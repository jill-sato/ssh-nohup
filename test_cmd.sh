#!/bin/bash

echo starting cmd script
i=0
while [ ${i} -lt 20 ] ; do
 printf "${i}\n"
 i=$((i+1))
 if [ ${i} -eq 10 ] ; then exit 5 ; fi
 sleep 1
done
echo done
