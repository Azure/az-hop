# Monitoring and Alerting
The [Azure Monitor Agent](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/agents-overview) can be installed on the following VMs to collect syslog messages and expose key metrics via [VM Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/vm/vminsights-overview): 
- Scheduler
- CycleCloud
- OnDemand
- Jumpbox 

The information exposed by the agent is used by azhop to trigger alerts for key situations that could disrupt your HPC environment in Azure.
## Enable Monitoring 
The monitoring agent requires the deployment of a [log analytics workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview), which provides administrators with a central location for analyzing syslog messages and the performance data of the target VMs. Consequently, to enable monitoring, you will need to specify in your configuration file to allow the creation of the log analytics workspace 
```yml
# Create a log analytics workspace to enable monitoring and alerting
log_analytics:
  create: true
```
## Alerts 
If alerting is enabled, azhop can alert administrators of the following situations: 
- Infrastructure VM is down 
- CycleCloud service is stopped or killed 
- ANF volume reaches a set threshold 
- VM disk volumes reach a set threshold

If any of these situations are detected, an email will be sent to administrators, who will be able to view more details on the alert from the Azure Portal.  

## Enabling Alerts 
If monitoring is enabled, alerts can be placed into effect through the configuration file:
```yml
alerting:
  enabled: true
  admin_email: admin.mail@contoso.com
```
Note, you will need to set the enabled option to true and you will also need to provide an email address for the alerts. If an email address is not provided, the alerts will not be enabled. 

## Configuring Alerts
The following alerts can be configured: 
- ANF volume reaches a set threshold 
- VM disk volumes reach a set threshold
 
The default behavior of these alerts is to send an email to the administrator if the ANF or disk volumes are up to 80% full, but the threshold can be changed. 

The following option in the configuration file can be used to define the threshold for the disk volumes: 
```yml
alerting:
  ---
  local_volume_threshold: 80
```

The following option in the configuration file can be used to define the threshold for the ANF volume: 
```yml
anf:
  ---
  alert_threshold: 80
```