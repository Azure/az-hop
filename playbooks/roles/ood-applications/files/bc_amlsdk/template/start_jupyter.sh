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


echo "notebook root= ${NOTEBOOK_ROOT}"
echo "building main notebook"
# have to be careful with AMLSDKJOBINPUTS as it may start with "--"
set -o xtrace
python nbbuilder.py -s $AMLSDKSUBSCRIPTION -rg $AMLSDKRESOURCEGROUP -ws $AMLSDKWORKSPACE -mt $AMLSDKSKU -mi $AMLSDKINSTANCECOUNT -j $AMLSDKJOBCODE -ji " $AMLSDKJOBINPUTS"
set +o xtrace


# List available kernels for debugging purposes
set -x
jupyter kernelspec list
{ set +x; } 2>/dev/null
echo "TTT - $(date)"

# Launch the Jupyter server
set -x
jupyter lab --config="${CONFIG_FILE}"
