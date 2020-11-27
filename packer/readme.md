# Building the images

First create an `options.json` file with the following fields:

```
{
    "var_subscription_id": "",
    "var_tenant_id": "",
    "var_client_id": "",
    "var_client_secret": "",
    "var_resource_group": "",
    "var_image": ""
}
```

Build an image as follows:

```
packer build -var-file=options.json centos-7.7-desktop-3d.json
```

