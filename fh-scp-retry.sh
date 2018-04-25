#!/bin/bash -e

SCP_OPTS=$1
SRC=$2
DEST=$3

MAXTRIES=10
ntries=0
while [ ${ntries} -lt  ${MAXTRIES} ]; do
  let ntries=ntries+1
  set +e
  scp ${SCP_OPTS} ${SRC} ${DEST}
  status=$?
  set -e
  if [ $status -eq 0 ]; then
    echo "### scp-retry: success after $ntries tries."
    exit 0
  else
    echo "### scp-retry: failed scp status=$status, ntries=$ntries"
    sleep 5
  fi
done
# exit with the last failed status.
exit $status
