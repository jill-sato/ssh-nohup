#!/bin/bash -e

export SSH_OPTS="-i ${HOME}/.ssh/foghorn-dev.pem"
export SSH_USERHOST="jenkins@jk.foghorn-systems.com"

export SSH_OPTS=" "
export SSH_USERHOST="pi@10.10.1.11"

readonly TEST_CMD=test_cmd.sh
#readonly TEST_CMD=test_cmd_long.sh
readonly SSH_NOHUP=$(dirname ${0})/ssh-nohup2.sh

# For testing
JOB_NAME=jill-test
BUILD_NUMBER=25

#echo REMOTE_TEST_CMD=`ssh -q ${SSH_OPTS} ${SSH_USERHOST} "mktemp"`
#REMOTE_TEST_CMD=`ssh -q ${SSH_OPTS} ${SSH_USERHOST} "mktemp"`
#echo scp -q ${SSH_OPTS} ${TEST_CMD} ${SSH_USERHOST}:${REMOTE_TEST_CMD}

REMOTE_TEST_CMD=/tmp/${JOB_NAME}-${BUILD_NUMBER}-${TEST_CMD}
printf "test.sh - sending ${TEST_CMD} ${REMOTE_TEST_CMD} script\n"
echo scp -q ${SSH_OPTS} ${TEST_CMD} ${SSH_USERHOST}:${REMOTE_TEST_CMD}
scp -q ${SSH_OPTS} ${TEST_CMD} ${SSH_USERHOST}:${REMOTE_TEST_CMD}

echo "calling ssh nohup on bash ${REMOTE_TEST_CMD}"
${SSH_NOHUP} bash ${REMOTE_TEST_CMD}
#echo "exit code - ${?}"
