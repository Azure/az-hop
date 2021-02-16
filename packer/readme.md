# Building the images

 - Fill up the `spn.json` with the SPN used by Packer and the keyvault in which it's secret is stored (using the spn name as a secret name)

```
{
  "spn_name": "",
  "key_vault": ""
}
```

The file `options.json` is automatically created for you after the infrastructure deployment, there is no need to update it.

It contains the following fields:

```
{
  "var_subscription_id": "",
  "var_resource_group": ""
}
```

Build an image with the `build_image.sh` helper script as follows:

```
./build_image.sh packer_file.json
```

>Note: Use the var_image variable in your image name, it will be replaced by the name of the packer file

To list existing marketplace image use this command
```bash
az vm image list -l westeurope -p Openlogic --all -o table
```
