#!/bin/bash

yum install -y cmake libnl3-devel

git clone https://github.com/linux-rdma/rdma-core.git
cd rdma-core
bash build.sh

cp build/bin/rdma_rename /usr/lib/udev/

cat <<EOF >/etc/udev/rules.d/60-ib.rules
ACTION=="add", ATTR{board_id}=="MSF0010110035", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED mlx5_an0"
ACTION=="add", ATTR{board_id}=="MT_0000000223", SUBSYSTEM=="infiniband", PROGRAM="rdma_rename %k NAME_FIXED mlx5_ib0"
EOF

#an_index=0
#ib_index=0
#
#while read line; do
#
#    device_name=${line% *}
#    device_type=${line#* }
#
#    if [ "$device_type" = "Ethernet" ]; then
#        rdma_rename $device_name NAME_FIXED mlx5_an${an_index}
#        an_index=$(($ib_index + 1))
#    elif [ "$device_type" = "Infiniband" ]; then
#        rdma_rename $device_name NAME_FIXED mlx5_ib${ib_index}
#        ib_index=$(($ib_index + 1))
#    else
#        echo "Unknown device type - $device_type"
#        exit 1
#    fi
#
#done <<< $(ibv_devinfo | grep 'hca_id\|link_layer' | sed 'N;s/\n/ /g' | sed 's/hca_id:\t//g;s/ \t*link_layer:\t*/ /g')

#[hpcadmin@ip-0A001005 ~]$ ibv_devinfo 
#hca_id: mlx5_an0
#        transport:                      InfiniBand (0)
#        fw_ver:                         14.25.8102
#        node_guid:                      000d:3aff:fe23:c2c6
#        sys_image_guid:                 0000:0000:0000:0000
#        vendor_id:                      0x02c9
#        vendor_part_id:                 4118
#        hw_ver:                         0x80
#        board_id:                       MSF0010110035
#        phys_port_cnt:                  1
#                port:   1
#                        state:                  PORT_ACTIVE (4)
#                        max_mtu:                4096 (5)
#                        active_mtu:             1024 (3)
#                        sm_lid:                 0
#                        port_lid:               0
#                        port_lmc:               0x00
#                        link_layer:             Ethernet
#
#hca_id: mlx5_1
#        transport:                      InfiniBand (0)
#        fw_ver:                         20.26.6200
#        node_guid:                      0015:5dff:fe33:ff30
#        sys_image_guid:                 b859:9f03:00c3:d886
#        vendor_id:                      0x02c9
#        vendor_part_id:                 4124
#        hw_ver:                         0x0
#        board_id:                       MT_0000000223
#        phys_port_cnt:                  1
#                port:   1
#                        state:                  PORT_ACTIVE (4)
#                        max_mtu:                4096 (5)
#                        active_mtu:             4096 (5)
#                        sm_lid:                 1
#                        port_lid:               285
#                        port_lmc:               0x00
#                        link_layer:             InfiniBand
