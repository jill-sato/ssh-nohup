#!/bin/bash -ex
# Be sure to escape \$ any values passed as $1
# so that the env vars are interpreted remotely.
REMOTE_CMD="$1"

### for testing from cmd line ###
#REMOTE_CMD="ls /tmp"
JOB_NAME=fh-ssh-nohup
BUILD_NUMBER=20
WORKSPACE=`pwd` 
WORKSPACE=$(dirname "$0")
export SSH_OPTS="-i ${pemFile}"
export SSH_USERHOST=${sshHost}
### end testing

readonly TEST_CMD=remote-cmd.sh
readonly SSH_NOHUP=ssh-nohup2.sh

# generate a script with the command inside.
# Don't escape ${REMOTE_CMD} because want it evaluated now.
rm -f ${WORKSPACE}/${TEST_CMD}
cat << EOF > ${WORKSPACE}/${TEST_CMD}
echo "### ${TEST_CMD}: executing REMOTE_CMD ${REMOTE_CMD}"
${REMOTE_CMD}
echo "### ${TEST_CMD}: done executing REMOTE_CMD ${REMOTE_CMD}"
EOF

# Generate unique script name on remote host based on job name and build #.
readonly REMOTE_TEST_CMD=/tmp/${JOB_NAME}-${BUILD_NUMBER}-${TEST_CMD}
echo "### Sending: scp -q ${SSH_OPTS} ${TEST_CMD} ${SSH_USERHOST}:${REMOTE_TEST_CMD}"
#scp -q ${SSH_OPTS} ${WORKSPACE}/${TEST_CMD} ${SSH_USERHOST}:${REMOTE_TEST_CMD}
${WORKSPACE}/fh-scp-retry.sh "-q ${SSH_OPTS}" "${WORKSPACE}/${TEST_CMD}" "${SSH_USERHOST}:${REMOTE_TEST_CMD}"

echo "### Calling ssh nohup on bash ${REMOTE_TEST_CMD}"
#bash -x ${FH_TOOLS_DEV}/${ORIG_JOB_NAME}/${SSH_NOHUP} bash ${REMOTE_TEST_CMD}
bash ${WORKSPACE}/${SSH_NOHUP} bash ${REMOTE_TEST_CMD}
