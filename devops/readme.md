This folder contains scripts and terraform files to allow the usage of a service principal name in the context of azure github actions pipelines.
When running outside of the context of a user, you need a Service Principal Name to create resources. A dedicated resource group will be created that will contains a key vault used to store the SPN secret used when running packer. That same SPN can also be used to run the github actions pipelines.

To build this :
 - create a `devops.tfvars` file with the following variables being set

 ```
location = "location"
resource_group = "mydevops_rg"
devops_spn = "spndevops"
 ```

 - run the following command being logged as a privilege account to create a KeyVault, SPN and grant privilege

```
  ./build.sh -v $(pwd)/devops.tfvars -f ./devops/tf -a apply
```

 