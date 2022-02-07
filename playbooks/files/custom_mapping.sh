#!/bin/bash
REX="([^@]+)%40foo.com"
INPUT_USER="$1"

if [[ $INPUT_USER =~ $REX ]]; then
  MATCH="${BASH_REMATCH[1]}"
  echo "$MATCH" | tr '[:upper:]' '[:lower:]'
else
  # can't write to standard out or error, so let's use syslog
  logger -t 'ood-mapping' "cannot map $INPUT_USER"

  # and exit 1
  exit 1
fi
