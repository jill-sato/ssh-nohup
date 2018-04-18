#!/bin/bash

echo starting ${0} script

# 60 * 60 * 10 hours
NSECS=36000

i=0
while [ ${i} -lt ${NSECS} ] ; do
  #printf "${i}\n"
  i=$((i+1))
  #if [ ${i} -eq 10 ] ; then exit 5 ; fi
  sleep 1
  # Print echo every 15 min
  if [ $(($i%900)) -eq 0 ]; then
    echo "### ${0}: 15 minutes up"
  fi
done

echo "done i = $i"
