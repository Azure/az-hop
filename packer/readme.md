# Building the images

The file `options.json` is automatically created for you after the infrastructure deployment, there is no need to update it.

It contains the following fields:

```
{
  "var_subscription_id": "",
  "var_resource_group": "",
  "spn_name" : "",
  "key_vault": ""
}
```

The key vault contains the SPN secret stored under the secret named with the SPN name. This is created and pre-filled when you build the infrastructure.

Build an image with the `build_image.sh` helper script as follows:

```
./build_image.sh packer_file.json
```

>Note: Use the var_image variable in your image name, it will be replaced by the name of the packer file
