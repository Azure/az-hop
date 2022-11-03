# Telemetry
When you build your HPC environment on azure via azhop, Microsoft can identify the use of azhop with the deployed Azure resources. Microsoft collects this information to provide the best experiences with their products and to operate their business. The telemetry is collected through customer usage attribution. The data is collected and governed by Microsoft's privacy policies.

If you do not wish to send usage data to Microsoft, you will need update your config file to include the following setting: 

`optout_telemetry: true`

The setting can be applied by uncommenting line 10 from the config file.

