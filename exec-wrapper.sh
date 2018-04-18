#!/bin/bash

# this script executes a command a captures the exit code
# it takes the command to execute from script args
# it captures the exit code into a file

STATUS_FILE=${1}
shift

${*}
echo ${?} > ${STATUS_FILE}