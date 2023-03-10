#!/usr/bin/env bash
echo "Starting main script..."
echo "TTT - $(date)"

## solve the non-root user problem
set -x
cat << EOF >/etc/rstudio/rserver.conf
rsession-which-r=/usr/local/bin/R
server-user=$USER
auth-none=1
EOF

# Launch the Rstudio server
set -x
/usr/lib/rstudio-server/bin/rserver --www-port ${port}
