#!/bin/bash

CURRENT_DATE=`date`

echo $CURRENT_DATE >> /tmp/health_info.txt
>&2 echo "stderr: script error happened!"
echo "stdout: script error happened!"
exit 10
