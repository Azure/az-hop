#!/bin/bash

nvidia-smi | grep NVIDIA
if [ $? -eq 1 ]; then 
    echo "ERROR"
    exit 1
fi

echo "PASSED"