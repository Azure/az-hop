#!/bin/bash
echo " ********************************************************************************** "
echo " *                                                                                * "
echo " *     PBS PRO                                                                    * "
echo " *                                                                                * "
echo " ********************************************************************************** "

cd /mnt

apt install libpq5 -y
wget -q https://vcdn.altair.com/rl/OpenPBS/openpbs_22.05.11.ubuntu_20.04.zip
unzip -o openpbs_22.05.11.ubuntu_20.04.zip
dpkg -i --force-overwrite --force-confnew ./openpbs_22.05.11.ubuntu_20.04/openpbs-execution_22.05.11-1_amd64.deb
rm -rf openpbs_22.05.11.ubuntu_20.04
rm -f openpbs_22.05.11.ubuntu_20.04.zip
