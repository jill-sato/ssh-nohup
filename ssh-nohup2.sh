#!/bin/bash -e

# Set true or false
DEBUG=true

# TODO add script arguments for
#        - command to run
#        - ssh_opts
#        - ssh_user
#        - ssh_host
#        - verbose
#        - debug
#        - usage (-h)

# TODO
# wrap scp and ssh commands into bash functions
# and handle resiliency (mktemp, scp, ps, kill)

# TODO
# change debug message to use ${0} for the script name (rather than hardcoded remote_spawn)

if [ -z "${SSH_OPTS}" ] ; then echo "ERROR - SSH_OPTS not set in environment" ; exit 1 ; fi
if [ -z "${SSH_USERHOST}" ] ; then echo "ERROR - SSH_OPTS not set in environment" ; exit 1 ; fi
if [ "${#*}" -lt 1 ] || [ -z "${1}" ] ; then echo "ERROR - usage ${0} CMD ..." ; exit 1 ; fi
if [ -z ${JOB_NAME} ]; then JOB_NAME=ssh-nohup; fi

readonly DEBUG_LOG=$(mktemp -t XXXssh-nohup)

debug() {
  local str=$1
  if [ "${DEBUG}" = "true" ]; then 
    echo "### ssh-nohup: ${str}"
    echo "### ssh-nohup: ${str}" >> ${DEBUG_LOG}
  fi
}

debug "DEBUG_LOG = ${DEBUG_LOG}"
debug "SCRIPT_PID = ${$}"

readonly CMD=${*}
readonly EXEC_WRAPPER=$(dirname ${0})/exec-wrapper.sh
readonly NOHUP_WRAPPER=$(dirname ${0})/nohup-wrapper.sh
readonly TAIL_WRAPPER=$(dirname ${0})/tail-wrapper.sh

REMOTE_TMP_DIR=`ssh -q ${SSH_OPTS} ${SSH_USERHOST} "mktemp -d -t ${JOB_NAME}.XXXXX"`
STATUS_FILE=${REMOTE_TMP_DIR}/status.txt
LOG=${REMOTE_TMP_DIR}/log.txt
debug "REMOTE_TMP_DIR = ${REMOTE_TMP_DIR}"

debug "Sending wrapper script ${EXEC_WRAPPER} to ${SSH_USERHOST}:${REMOTE_TMP_DIR}"
scp -q ${SSH_OPTS} ${EXEC_WRAPPER} ${SSH_USERHOST}:${REMOTE_TMP_DIR}/

debug "Sending nohup script ${NOHUP_WRAPPER} to ${SSH_USERHOST}:${REMOTE_TMP_DIR}"
scp -q ${SSH_OPTS} ${NOHUP_WRAPPER} ${SSH_USERHOST}:${REMOTE_TMP_DIR}/

debug "Sending tail script ${TAIL_WRAPPER} to ${SSH_USERHOST}:${REMOTE_TMP_DIR}"
scp -q ${SSH_OPTS} ${TAIL_WRAPPER} ${SSH_USERHOST}:${REMOTE_TMP_DIR}/

debug "CMD is ${CMD}"
debug "Invoking nohup wrapper 'ssh ${SSH_OPTS} ${SSH_USERHOST} bash ${REMOTE_TMP_DIR}/nohup-wrapper.sh ${LOG} ${STATUS_FILE} ${CMD}'"
PID=`ssh ${SSH_OPTS} ${SSH_USERHOST} "bash ${REMOTE_TMP_DIR}/nohup-wrapper.sh ${LOG} ${STATUS_FILE} ${CMD}"`
debug "Remote PID of ssh nohup-wrapper = ${PID}"

print_children_pids(){
  ps -e | grep ${1} | awk '{print $1}' | grep -v ${PPID} | grep -v ${1} | sort | uniq | tr '\n' ' '
}

remote_print_children_pids(){
  ssh ${SSH_OPTS} ${SSH_USERHOST} "ps -e" | grep ${1} | awk '{print $1}' | grep -v ${PPID} | grep -v ${1} | sort | uniq | tr '\n' ' '
}

trap_handler(){
  debug "trap_handler - PID = ${$}"

  # kill remote pids
  local remote_pids=`remote_print_children_pids ${PID}`
  debug "trap_handler - remote kill -9 ${remote_pids} ${PID}"
  ssh ${SSH_OPTS} ${SSH_USERHOST} "bash -c 'kill -9 ${remote_pids} ${PID}'" > /tmp/k1 2>&1 || true

  # kill local pids
  local pids=`print_children_pids ${$}`
  pids="${pids} `print_children_pids ${TAIL_LOOP_PID}`"
  debug "trap_handler - local pids=${pids}; TAIL_LOOP_PID=${TAIL_LOOP_PID} self=${$}"
  #pids="${pids} ${TAIL_LOOP_PID} ${$}"
  pids="${pids} ${TAIL_LOOP_PID} "
  debug "trap_handler - local kill -9: ${pids}"
  kill -9 ${pids} > /tmp/k2 2>&1 || true

  # uncomment later for clean hup
  #rm -rf ${REMOTE_TMP_DIR}
  # remove log file and status file
  #ssh ${SSH_OPTS} ${SSH_USERHOST} "bash -c 'rm -f ${LOG} ${STATUS_FILE}'"
}
term_handler() {
  debug "term_handler"
  trap_handler
}
int_handler() {
  debug "int_handler"
  trap_handler
}
quit_handler() {
  debug "quit_handler"
  trap_handler
}
exit_handler() {
  debug "exit_handler"
  trap_handler
}
trap "term_handler" TERM 
trap "int_handler" INT 
trap "quit_handler" QUIT 
trap "exit_handler" EXIT

# tail the remote process output in a subshell in the background
(
  while true ; do 
  debug "start tail-wrapper"
  ssh -q ${SSH_OPTS} ${SSH_USERHOST} "bash ${REMOTE_TMP_DIR}/tail-wrapper.sh ${PID} ${LOG}" || true
  done
) &
TAIL_LOOP_PID=${!}
debug "TAIL_LOOP_PID is pid of the ssh cmd to tail: ${TAIL_LOOP_PID}"

# wait for remote process to end
while true
do
  retries=0
  while [ ${retries} -lt 10 ] ; do
    isalive=`ssh -q ${SSH_OPTS} ${SSH_USERHOST} "ps --no-headers ${PID} | wc -l"`
    if [ ${PIPESTATUS[0]} -eq 0 ] ; then break ; fi
    if [ ${retries} -eq 9 ] ; then
      # abort since unable to determine liveliness of the process
      # print some error message and exit
      debug "ERROR - Unable to determine if remote process ${PID} is alive after 10 retries"
      exit 1
    fi
    retries=$((retries+1))
  done
  if [ "${isalive}" -gt 0 ] ; then
    # process is alive, keep waiting
    sleep 2
  else
    # process is dead, stop here
    break;
  fi
done

debug "retrieving exit code"
EXIT_CODE=`ssh ${SSH_OPTS} ${SSH_USERHOST} "cat ${STATUS_FILE}"`

debug "EXIT_CODE=${EXIT_CODE}"
exit ${EXIT_CODE}
