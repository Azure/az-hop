#!/bin/bash
REX="([^@]+)%40domain.com" # To extract user from user%40domain.com
#REX="([^@]+)%40\w+.com" # To extract user from any .com domains
#REX="(^\w+)" # To extract firstname from firstname.lastname@domain.com
INPUT_USER="$1"

if [[ $INPUT_USER =~ $REX ]]; then
  MATCH="${BASH_REMATCH[1]}"
  echo "${MATCH:0:20}" | tr '[:upper:]' '[:lower:]'
else
  # can't write to standard out or error, so let's use syslog
  logger -t 'ood-mapping' "cannot map $INPUT_USER"

  # and exit 1
  exit 1
fi
