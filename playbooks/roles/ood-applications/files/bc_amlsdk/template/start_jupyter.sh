#!/usr/bin/env bash
echo "Starting main script..."
echo "TTT - $(date)"

echo "Installing azure machine learning tools..."
pip install azure-cli
pip install azureml-core
pip install azure-ai-ml
pip install azure.identity

echo "Installing customized jupyter launcher..."
pip install jupyter_app_launcher
jupyter labextension list

JUPYTERAPPLAUNCHERDIR="${NOTEBOOK_ROOT}"/.local/share/jupyter/jupyter_app_launcher/
mkdir $JUPYTERAPPLAUNCHERDIR
JUPYTERAPPLAUNCHERCONF=$JUPYTERAPPLAUNCHERDIR/config.yaml

cat << EOF > $JUPYTERAPPLAUNCHERCONF
- title: AzureML Notebook
  description: AzureML notebook
  source: ${NOTEBOOK_ROOT}/new1.ipynb
  cwd: ${NOTEBOOK_ROOT}
  type: notebook
  catalog: Notebook
  icon: $JUPYTERAPPLAUNCHERDIR/azure-ml.svg
EOF

cp azure-ml.svg $JUPYTERAPPLAUNCHERDIR

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
python nbbuilder.py -s $AMLSDKSUBSCRIPTION -l $AMLSDKLOCATION -rg $AMLSDKRESOURCEGROUP -ws $AMLSDKWORKSPACE -mt $AMLSDKSKU -mi $AMLSDKINSTANCECOUNT -j $AMLSDKJOBCODE -ji " $AMLSDKJOBINPUTS"
set +o xtrace


# List available kernels for debugging purposes
set -x
jupyter kernelspec list
{ set +x; } 2>/dev/null
echo "TTT - $(date)"

# Launch the Jupyter server
set -x
jupyter lab --config="${CONFIG_FILE}"
