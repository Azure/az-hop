#!/usr/bin/env bash
echo "Starting main script..."
echo "TTT - $(date)"

# install dependencies
pip install ipyfilechooser voila jupyter_app_launcher
jupyter labextension list

JUPYTERAPPLAUNCHERDIR="${NOTEBOOK_ROOT}/.local/share/jupyter/jupyter_app_launcher"
mkdir -p $JUPYTERAPPLAUNCHERDIR
JUPYTERAPPLAUNCHERCONF=$JUPYTERAPPLAUNCHERDIR/config.yaml

mkdir $HOME/jupyter_nb_apps

cp OFLogView.ipynb $HOME/jupyter_nb_apps
cp OFLogView.svg $JUPYTERAPPLAUNCHERDIR

cat << EOF > $JUPYTERAPPLAUNCHERCONF
- title: OpenFOAM Log Viewer
  description: Plot log files for OpenFOAM
  source: /node/${host}/${port}/voila/render/jupyter_nb_apps/OFLogView.ipynb
  type: url
  catalog: OpenFOAM
  icon: $JUPYTERAPPLAUNCHERDIR/OFLogView.svg
  args:
      sandbox: [ 'allow-same-origin', 'allow-scripts', 'allow-downloads', 'allow-modals', 'allow-popups']
      referrerPolicy: ['no-referrer']
EOF

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
