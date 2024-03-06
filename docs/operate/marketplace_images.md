# azhop marketplace images references
There is a list of predefined images pushed in the azure marketplace under the publisher name `azhpc`. You can list those by running the following command or by using the [Azure VM Image List](https://az-vm-image.info/?cmd=--all+--publisher+azhpc) site. 
```
az vm image list --all --publisher azhpc
```

## How these images are built ?
These images are built with the definitions and scripts located in the `packer` directory. Once built they are tagged with the pattern `YYYY.mmdd.HHMM`so you can easily retrieve from the repo history which changes have been done in the `packer/scripts` folder.

## List of published images and base
These ready to go images are built on top of existing Azure HPC images, and the table below will help you to map the azhop image version with the azure hpc image version.

|Publisher|Offer|SKU|Version|Base|Packer File|
|---------|-----|---|-------|-----------|----|
|**azhpc**|**azhop-compute**|**almalinux-8_7**|||**azhop-compute-almalinux-8_7**|
||||2023.0612.1504|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101||
||||2023.0705.1612|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101||
||||2023.0926.1356|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101||
||||2024.0219.1104|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023111401||
||||2024.0305.1314|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023111401||
|**azhpc**|**azhop-compute**|**ubuntu-20_04**|||**azhop-compute-ubuntu-20_04**|
||||2023.0313.1209|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501||
||||2023.0612.1507|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501||
||||2023.0706.1116|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023063001||
||||2023.0926.1423|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023080201||
||||2204.0219.1105|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023111801||
||||2024.0305.1320|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023111801||
|**azhpc**|**azhop-desktop**|**almalinux-8_7**|||**azhop-desktop-almalinux-8_7**|
||||2023.0612.1534|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101||
||||2023.0705.1621|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101||
||||2023.0926.1429|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101||
||||2024.0219.1109|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023111401||
||||2024.0305.1321|almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023111401||
|**azhpc**|**azhop-desktop**|**ubuntu-20_04**|||**azhop-desktop-ubuntu-20_04**|
||||2023.0330.1029|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023031501||
||||2023.0706.1123|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023063001||
||||2023.0926.1436|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023080201||
||||2024.0219.1113|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023111801||
||||2024.0305.1339|microsoft-dsvm:ubuntu-hpc:2004:20.04.2023111801||


## End of Support
|Publisher|Offer|SKU|Version|Date|
|---------|-----|---|-------|----|
|azhpc|azhop-compute|centos-7_9|all|June 30, 2024
|azhpc|azhop-desktop|centos-7_9-gen1|all|June 30, 2024
|azhpc|azhop-compute|ubuntu-18_04|all|Deprecated

