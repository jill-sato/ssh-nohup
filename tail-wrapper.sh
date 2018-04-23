#!/bin/bash -e

DEBUG=true

# this script takes a text file to to tail and the pid of a process to monitor
# the tail should run as long as the process is alive

# TODO replace this script to not use tail
# use tail -n + grep to only show a certain window
# return line number to caller to maintain state and resume

readonly PID=${1}
readonly LOG=${2}
readonly DEBUG_LOG=$(mktemp -t XXXtail-wrapper)

debug() {
  local str=$1
  if [ "${DEBUG}" = "true" ]; then 
    echo "### tail-wrapper: ${str}" 
    echo "### tail-wrapper: ${str}" >> ${DEBUG_LOG}
  fi
}

debug "DEBUG_LOG = ${DEBUG_LOG}"
debug "PID to tail on = ${PID}"

tail -f ${LOG} &
TAIL_PID=${!}
debug "TAIL_PID = ${TAIL_PID}"

trap_handler(){
  debug "trap_handler - kill -9 TAIL_PID=${TAIL_PID}"
  kill -9 ${TAIL_PID}  > /dev/null 2>&1 || true

  # clean up debug log if debug not set. 
  if [ "${DEBUG}" = "false" ]; then 
    rm -f ${DEBUG_LOG}
  fi

  exit 0
}
trap "trap_handler" TERM INT QUIT EXIT

debug "Check if PID $PID is running..."
while [ `ps --no-headers ${PID} | wc -l | awk '{print $1}'` -eq 1 ]
do
    #debug "Keep checking if PID $PID is running..."
    sleep 2
done
debug "Outside while loop because PID $PID is no longer running"

debug "kill -9 TAIL_PID=${TAIL_PID}"
kill -9 ${TAIL_PID}  > /dev/null 2>&1 || true
# clean up debug log if debug not set. 
if [ "${DEBUG}" = "false" ]; then 
  rm -f ${DEBUG_LOG}
fi

# Sleep or the ssh tail lop in ssh-nohup will keep tailing output.
sleep 10
