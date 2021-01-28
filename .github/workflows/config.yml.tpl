---
location: __LOCATION__
resource_group: __RESOURCE_GROUP__
homefs_size_tb: 4
admin_user: hpcadmin
homedir_mountpoint: /anfhome
users: # TODO
  - name: user1
    uid: 10001
    gid: 5000
    shell: /bin/bash
    home: /anfhome/user1
    admin: true
  - name: user2
    uid: 10002
    gid: 5000
    shell: /bin/bash
    home: /anfhome/user2
    admin: true
groups: # TODO
  - name: users
    gid: 5000
queues:
  - name: execute
    vm_size: Standard_F2s_v2
    max_core_count: 1024
    image: OpenLogic:CentOS-HPC:7.7:latest
  - name: hc44rs
    vm_size: Standard_HC44rs
    max_core_count: 1024
    image: OpenLogic:CentOS-HPC:7.7:latest
  - name: hb60rs
    vm_size: Standard_HB60rs
    max_core_count: 1024
    image: OpenLogic:CentOS-HPC:7.7:latest
  - name: hb120rs_v2
    vm_size: Standard_HB120rs_v2
    max_core_count: 1024
    image: OpenLogic:CentOS-HPC:7.7:latest