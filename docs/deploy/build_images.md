# Build Images

**az-hop** provides a set of pre-configured packer configuration files that can be used to build custom images. The utility script `./packer/build_image.sh` is in charge of building these images with packer and push them into the Shared Image Gallery of the environment.

## Pre-requisites
As packer used a Service Principal Name to create the azure resources, you need to create one upfront, store the password in a keyvault secret, and configure the `spn.json` parameter file used by the `build_image.sh` script.

### Create a Service Principal Name

Run this command to generate a Service Principal Name. Keep the password value somewhere safe as it won't be shown again.
```bash
az ad sp create-for-rbac --name azhop-packer-spn
{
  "appId": "<some-generated-guid>",
  "displayName": "azhop-packer-spn",
  "name": "http://azhop-packer-spn",
  "password": "<generated-password>",
  "tenant": "<your-tenant-id>"
}
```

### Add the password in a keyvault secret

```bash
az keyvault secret set --value <generated-password> --name azhop-packer-spn --vault-name <your-keyvault>
```

### Create the spn.json parameter file

In the `packer` directory create a file named `spn.json` and add this content

```
{
  "spn_name": "azhop-packer-spn",
  "key_vault": "<your-keyvault>"
}
```

## Image definition in the configuration file

Image definitions have to be specified in the `config.yml` configuration file. These values are used to map a packer image file and the image definition in the Shared Image Gallery. Below is an example of such configuration, note that the image name must match an existing packer file.

```yml
images:
  - name: azhop-centos78-v2-rdma
    publisher: azhop
    offer: CentOS
    sku: 7.8-gen2
    hyper_v: V2
    os_type: Linux
    version: 7.8 
```

## Build an image
Building an image is done by the utility script `packer/build_image.sh` and requires a packer input file. az-hop provides a set of pre-defined image files like :
- `azhop-centos78-v2-rdma.json` this is an CentOS 7.8 HPC image with the az-hop additions for compute nodes  
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
./build_image.sh -i azhop-centos78-v2-rdma.json
```

## Update the Cycle cluster template
Once images have been built you need to update the Cycle cluster template to match the exact image ID of the images pushed into the Shared Image Gallery. To do so just run the install step on the ccpbs target.

```bash
./install.sh ccpbs
```

Once done your new images are ready to use in azhop.
