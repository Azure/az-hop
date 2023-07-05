# Using bicep instead of Terraform
This is the scenario to provide compatibility with the existing mode of deploying using the local configuration file from either a local machine or an existing deployer VM.
- from a local machine "az login" with your user name.
- from a deployer VM "az login -i", the VM should have system assigned identity with the right roles as defined in the documentation.

From the root of the `azhop` directory run this 

```bash
./build.sh -a <plan, apply> -l bicep
```
