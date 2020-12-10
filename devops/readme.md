This folder contains scripts and terraform files to allow the usage of a service principal name in the context of azure github actions pipelines.
When running outside of the context of a user, you need a Service Principal Name to create resources. A dedicated resource group will be created that will contains a key vault used to store the SPN secret used when running packer. That same SPN can also be used to run the github actions pipelines.

