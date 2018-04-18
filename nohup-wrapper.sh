#!/bin/bash

# this script executes nohup in the background and prints the pid in stdout

readonly EXEC_WRAPPER=$(dirname ${0})/exec-wrapper.sh
LOG_FILE=${1}
shift

nohup bash ${EXEC_WRAPPER} ${*} > ${LOG_FILE} 2>&1 &
echo ${!}