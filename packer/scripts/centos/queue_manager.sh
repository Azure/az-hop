#!/bin/bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUEUEMANAGER=${1:-slurm}

case $QUEUEMANAGER in
    openpbs|slurm)
        $THIS_DIR/$QUEUEMANAGER.sh
    ;;
    all)
        $THIS_DIR/openpbs.sh
        $THIS_DIR/slurm.sh
    ;;
esac
