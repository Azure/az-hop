# azhop marketplace images references
There is a list of predefined images pushed in the azure marketplace under the publisher name `azhpc`. You can list those by running the following command or by using the [Azure VM Image List](https://az-vm-image.info/?cmd=--all+--publisher+azhpc) site. 
```
az vm image list --all --publisher azhpc
```

These ready to go images are built on top of existing Azure HPC images, and the table below will help you to map the azhop image version with the azure hpc image version.

|Publisher|Offer|SKU|Version|Base|
|---------|-----|---|-------|----|
|azhpc|azhop-compute|almalinux-8_7|2023.0612.1504|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-compute|almalinux-8_7|2023.0705.1612|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-compute|almalinux-8_7|2023.0926.1356|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-compute|centos-7_9|2022.1221.1441|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101
|azhpc|azhop-compute|centos-7_9|2023.0313.1210|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|centos-7_9|2023.0612.1506|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|centos-7_9|2023.0705.1615|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|centos-7_9|2023.0927.1020|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|ubuntu-18_04|2023.0313.1210|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023031501|
|azhpc|azhop-compute|ubuntu-18_04|2023.0612.1507|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023031501|
|azhpc|azhop-compute|ubuntu-18_04|2023.0706.1116|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023063001|
|azhpc|azhop-compute|ubuntu-18_04|2023.0926.1359|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023063001|
|azhpc|azhop-compute|ubuntu-20_04|2023.0313.1209|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501|
|azhpc|azhop-compute|ubuntu-20_04|2023.0612.1507|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501|
|azhpc|azhop-compute|ubuntu-20_04|2023.0706.1116|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023063001|
|azhpc|azhop-compute|ubuntu-20_04|2023.0926.1423|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023080201|
|azhpc|azhop-desktop|almalinux-8_7|2023.0612.1534|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-desktop|almalinux-8_7|2023.0705.1621|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-desktop|almalinux-8_7|2023.0926.1429|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-desktop|centos-7_9|2022.1221.1451|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0313.1245|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0612.1540|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0705.1648|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0927.1028|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9-gen1|2022.1221.1457|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0313.1257|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0612.1551|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0705.1653|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0927.1119|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|ubuntu-20_04|2023.0330.1029|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501|
|azhpc|azhop-desktop|ubuntu-20_04|2023.0706.1123|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023063001|
|azhpc|azhop-desktop|ubuntu-20_04|2023.0926.1436|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023080201|
