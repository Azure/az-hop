# Build Images

**az-hop** provides a set of pre-configured packer configuration files that can be used to build custom images. The utility script `./packer/build_image.sh` is in charge of building these images with packer and push them into the Shared Image Gallery of the environment.

## Pre-requisites
As packer used a Service Principal Name to create the azure resources, you need to create one upfront, store the password in a keyvault secret, and configure the `spn.json` parameter file used by the `build_image.sh` script.

See the [Azure Pre-requisites](azure_prereqs.md) page for more details.

### Using an existing Service Principal Name
If you have already an existing Service Principal Name, make sure it's granted the `contributor` role. 
### Using an spn.json parameter file

In the `packer` directory create a file named `spn.json` and add this content

```
{
  "spn_name": "<your-spn-name>",
  "key_vault": "<your-keyvault>"
}
```

If you have not created the SPN, then you need to have read permission in the Azure Directory in order for the build_image script to retrieve the Application ID and the Tenant ID.

### Using environment variables
If your account can't read the SPN details from the Active Directory then set these environment variables instead :
```bash
  export ARM_CLIENT_ID=<spn_add_id>
  export ARM_TENANT_ID=<spn_tenant_id>
  export ARM_CLIENT_SECRET="<spn_secret>"
```

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
Once images have been built you need to update the Cycle cluster template to match the exact image ID of the images pushed into the Shared Image Gallery. To do so just run the install step on the ccpbs target.

```bash
./install.sh ccpbs
```

Once done your new images are ready to use in azhop.
