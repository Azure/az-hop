#!/usr/bin/env bash
echo "Starting main script..."
echo "TTT - $(date)"

#
# Start Jupyter server
#

# Set working directory to notebook root directory
cd "${NOTEBOOK_ROOT}"
echo "TTT - $(date)"

# List available kernels for debugging purposes
set -x
jupyter kernelspec list
{ set +x; } 2>/dev/null
echo "TTT - $(date)"

# Launch the Jupyter server
set -x
jupyter lab --config="${CONFIG_FILE}"
