# azhop marketplace images references
There is a list of predefined images pushed in the azure marketplace under the publisher name `azhpc`. You can list those by running the following command or by using the [Azure VM Image List](https://az-vm-image.info/?cmd=--all+--publisher+azhpc) site. 
```
az vm image list --all --publisher azhpc
```

## How these images are built ?
These images are built with the definitions and scripts located in the `packer` directory. Once built they are tagged with the pattern `YYYY.mmdd.HHMM`so you can easily retrieve from the repo history which changes have been done in the `packer/scripts` folder.

## List of published images and base
These ready to go images are built on top of existing Azure HPC images, and the table below will help you to map the azhop image version with the azure hpc image version.

|Publisher|Offer|SKU|Version|Packer File|Base|
|---------|-----|---|-------|-----------|----|
|azhpc|azhop-compute|almalinux-8_7|2023.0612.1504|azhop-compute-almalinux-8_7|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-compute|almalinux-8_7|2023.0705.1612|azhop-compute-almalinux-8_7|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-compute|almalinux-8_7|2023.0926.1356|azhop-compute-almalinux-8_7|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-compute|centos-7_9|2022.1221.1441|azhop-compute-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101
|azhpc|azhop-compute|centos-7_9|2023.0313.1210|azhop-compute-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|centos-7_9|2023.0612.1506|azhop-compute-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|centos-7_9|2023.0705.1615|azhop-compute-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|centos-7_9|2023.0927.1020|azhop-compute-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-compute|ubuntu-18_04|2023.0313.1210|azhop-compute-ubuntu-18_04|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023031501|
|azhpc|azhop-compute|ubuntu-18_04|2023.0612.1507|azhop-compute-ubuntu-18_04|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023031501|
|azhpc|azhop-compute|ubuntu-18_04|2023.0706.1116|azhop-compute-ubuntu-18_04|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023063001|
|azhpc|azhop-compute|ubuntu-18_04|2023.0926.1359|azhop-compute-ubuntu-18_04|microsoft-dsvm:ubuntu-hpc:1804:18.04.2023063001|
|azhpc|azhop-compute|ubuntu-20_04|2023.0313.1209|azhop-compute-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501|
|azhpc|azhop-compute|ubuntu-20_04|2023.0612.1507|azhop-compute-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501|
|azhpc|azhop-compute|ubuntu-20_04|2023.0706.1116|azhop-compute-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023063001|
|azhpc|azhop-compute|ubuntu-20_04|2023.0926.1423|azhop-compute-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023080201|
|azhpc|azhop-desktop|almalinux-8_7|2023.0612.1534|azhop-desktop-almalinux-8_7|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-desktop|almalinux-8_7|2023.0705.1621|azhop-desktop-almalinux-8_7|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-desktop|almalinux-8_7|2023.0926.1429|azhop-desktop-almalinux-8_7|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101|
|azhpc|azhop-desktop|centos-7_9|2022.1221.1451|azhop-desktop-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0313.1245|azhop-desktop-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0612.1540|azhop-desktop-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0705.1648|azhop-desktop-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9|2023.0927.1028|azhop-desktop-centos-7_9|OpenLogic:CentOS-HPC:7_9-gen2:7.9.2022040101|
|azhpc|azhop-desktop|centos-7_9-gen1|2022.1221.1457|azhop-desktop-centos-7_9-gen1|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0313.1257|azhop-desktop-centos-7_9-gen1|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0612.1551|azhop-desktop-centos-7_9-gen1|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0705.1653|azhop-desktop-centos-7_9-gen1|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|centos-7_9-gen1|2023.0927.1119|azhop-desktop-centos-7_9-gen1|OpenLogic:CentOS-HPC:7_9:7.9.2022040100|
|azhpc|azhop-desktop|ubuntu-20_04|2023.0330.1029|azhop-desktop-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501|
|azhpc|azhop-desktop|ubuntu-20_04|2023.0706.1123|azhop-desktop-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023063001|
|azhpc|azhop-desktop|ubuntu-20_04|2023.0926.1436|azhop-desktop-ubuntu-20_04|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023080201|
