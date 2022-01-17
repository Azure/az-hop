# Build Images

**az-hop** provides a set of pre-configured packer configuration files that can be used to build custom images. The utility script `./packer/build_image.sh` is in charge of building these images with packer and push them into the Shared Image Gallery of the environment.

## Pre-requisites
You need to be authenticated thru `az login` or from a VM with a System Assigned managed identity in order to build images. The script will automatically detect in which mode and will set the required values needed by Packer.

## Image definition in the configuration file

Image definitions have to be specified in the `config.yml` configuration file. These values are used to map a packer image file and the image definition in the Shared Image Gallery. Below is an example of such configuration, note that the image name must match an existing packer file.

```yml
images:
  - name: azhop-centos79-v2-rdma
    publisher: azhop
    offer: CentOS
    sku: 7.9-gen2
    hyper_v: V2
    os_type: Linux
    version: 7.9 
```

## Build an image
Building an image is done by the utility script `packer/build_image.sh` and requires a packer input file. az-hop provides a set of pre-defined image files like :
- `azhop-centos79-v2-rdma-gpgpu.json` this is an CentOS 7.9 HPC image with the az-hop additions for compute nodes  
- `centos-7.8.desktop-3d.json` this is an CentOS 7.8 HPC image with the right GPU drivers configured for remote visualization nodes

```bash
Usage build_image.sh 
  Required arguments:
    -i|--image <image_file.json> | image packer file
   
  Optional arguments:
    -o|--options <options.json>  | file with options for packer generated in the build phase
    -f|--force                   | overwrite existing image and always push a new version in the SIG
```

The `build_image.sh` script will :
- build a managed image with packer, 
- tag this image with the checksum of the scripts called to build that image, 
- tag it with a version, 
- create the image definition in the Shared Image Gallery if it doesn't exists
- push the managed image in the Shared Image Gallery

Overall this can take between 30 and 45 minutes and sometimes more.

For example, to build the compute nodes image, run this command
```bash
cd packer
./build_image.sh -i azhop-centos79-v2-rdma-gpgpu.json
```

## Update the Cycle cluster template
>NOTE: To be done only when updating a system already configured

Once all images have been built you need to update the configuration file to specify which images to use and then update the Cycle cluster template to match the exact image ID of the images pushed into the Shared Image Gallery. 

To specify the new custom images to use, just comment the default `image: OpenLogic:CentOS-HPC:7_9-gen2:latest` values and uncomment the line below which contains the image definition to use from the Shared Image Gallery.

*Before the update*
```yml
queues:
  - name: hb120v3
    vm_size: Standard_HB120rs_v3
    max_core_count: 1200
    image: OpenLogic:CentOS-HPC:7_9-gen2:latest
#    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
    # Queue dedicated to GPU remote viz nodes. This name is fixed and can't be changed
  - name: viz3d
    vm_size: Standard_NV6
    max_core_count: 24
    image: OpenLogic:CentOS-HPC:7_9-gen2:latest
#    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/centos-7.8-desktop-3d/latest
    # Queue dedicated to non GPU remote viz nodes. This name is fixed and can't be changed
```

*After the update*
```yml
queues:
  - name: hb120v3
    vm_size: Standard_HB120rs_v3
    max_core_count: 1200
#    image: OpenLogic:CentOS-HPC:7_9-gen2:latest
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
    # Queue dedicated to GPU remote viz nodes. This name is fixed and can't be changed
  - name: viz3d
    vm_size: Standard_NV6
    max_core_count: 24
#    image: OpenLogic:CentOS-HPC:7_9-gen2:latest
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/centos-7.8-desktop-3d/latest
```

Then update the Cycle project by running this playbook :

```bash
./install.sh cccluster
```

Once done your new images are ready to be used in azhop.
> Note: For the new image to be used by new instances, make sure that all the existing one have been drained.

## Adding new packages in a custom image

Sometimes you need to add missing runtime packages in the custom image built or change some settings. This can be done by either add a new script in the packer JSON configuration files or by updating one of the existing script called by packer.

For example, below is the content of the `centos-7.8-desktop-3d.json` packer file, if you want to add custom packages one way would be to change the `desktop-packages.sh` located in the `./packer/scripts` directory.

```yml
    "provisioners": [
        {
            "type": "file",
            "source": "scripts",
            "destination": "/tmp"
        },
        {
            "execute_command": "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'",
            "inline": [
                "chmod +x /tmp/scripts/*.sh",
                "/tmp/scripts/linux-setup.sh",
                "/tmp/scripts/lustreclient2.12.5_centos7.8.sh",
                "/tmp/scripts/interactive-desktop-3d.sh",
                "/tmp/scripts/desktop-packages.sh",
                "/tmp/scripts/pbspro.sh",
                "/tmp/scripts/telegraf.sh",
                "rm -rf /tmp/scripts",
                "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
            ],
            "inline_shebang": "/bin/sh -x",
            "type": "shell",
            "skip_clean": true
        }
    ]
```

Rebuilding a new image version is done by following the steps above.

> Note: For the new image to be used by new instances, make sure that all the existing one have been drained.