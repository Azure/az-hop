#!/bin/bash

cp ../files/autostop.rb /opt/cycle/jetpack/system/bootstrap/autostop.rb
chmod 700 /opt/cycle/jetpack/system/bootstrap/autostop.rb

#write out current crontab
crontab -l > tempcron
#echo new cron into cron file
echo "* * * * * /opt/cycle/jetpack/system/bootstrap/cron_wrapper.sh /opt/cycle/jetpack/system/bootstrap/autostop.rb >> /opt/cycle/jetpack/logs/autostop.out 1>&2" >> tempcron
#install new cron file
crontab tempcron

rm tempcron
