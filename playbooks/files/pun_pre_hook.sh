#!/bin/bash
# Initialize the user environment the first time it logs in
while (( "$#" )); do
  case "${1}" in
    --user)
      OOD_USER=${2}
      shift 2
  esac
done

su - $OOD_USER
