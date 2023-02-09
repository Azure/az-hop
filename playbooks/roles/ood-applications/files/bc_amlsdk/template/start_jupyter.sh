#!/usr/bin/env bash
echo "Starting main script..."
echo "TTT - $(date)"

#
# Start Jupyter server
#

# Set working directory to notebook root directory

cp nbbuilder.py "${NOTEBOOK_ROOT}"/
cp amlwrapperfunctions.py "${NOTEBOOK_ROOT}"/
cd "${NOTEBOOK_ROOT}"
echo "TTT - $(date)"

echo "building main notebook"
python nbbuilder.py -s "TBD"


# List available kernels for debugging purposes
set -x
jupyter kernelspec list
{ set +x; } 2>/dev/null
echo "TTT - $(date)"

# Launch the Jupyter server
set -x
jupyter lab --config="${CONFIG_FILE}"
