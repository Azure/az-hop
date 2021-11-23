#!/bin/bash

nvidia-smi 
if [ $? -eq 1 ]; then 
    echo "ERROR"
    exit 1
fi

echo "PASSED"