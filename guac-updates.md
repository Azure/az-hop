azhop-guac
- modified src/guac/spooler.py
- added daemon.py
- run as follows:
    source /opt/cycle/guac/venv/bin/activate
    python ~hpcuser/azhop-guac/src/daemon.py -c /opt/cycle/guac/autoscale.json
- systemd script
    # cat /etc/systemd/system/guacspoold.service
    [Unit]
    Description=The spooler for autoscaling guacamole instances
    After=syslog.target network.target remote-fs.target nss-lookup.target
    [Service]
    Type=simple
    PIDFile=/run/guacspoold.pid
    ExecStart=/bin/bash -c 'source /opt/cycle/guac/venv/bin/activate; python ~hpcuser/azhop-guac/src/daemon.py -c /opt/cycle/guac/autoscale.js
    on'
    Restart=always
    [Install]
    WantedBy=multi-user.target
- Need to install as part of azhop-guac and might be better to have a script for the execstart
- Enable service with:
    systemctl enable guacspoold.service
    systemctl start guacspoold.service
- TODO: update packaging and install

Guac application:
- git repo: https://github.com/edwardsp/ondemand_bc_guacamole
- TODO: install app with ansible

ondemand:
- https://github.com/edwardsp/ondemand.git
- my repo adds jobstatusdata.rb to handle guacamole (in the dashboard app)
- dashboard app needs to be put in /var/www/ood/apps/sys (setup in hpcuser dev for current deployment)
  - Docs for installing apps: https://osc.github.io/ood-documentation/master/installation/from-source/core-apps.html
- TODO: Gemfile needs to update the ood_core (using local version in hpcuser dev for current deployment)

ood_core
- https://github.com/edwardsp/ood_core.git
- lib/ood_core/batch_connect/templates/guacamole.rb
- lib/ood_core/job/adapters/guacamole.rb
- spec/job/adapters/guacamole_spec.rb
- TODO: create gem for ood_core that ondemand will use

Notes:
- Setup env for building:
    source scl_source enable rh-nodejs12 rh-ruby27 httpd24 ondemand