# Clusters access

From the portal, select the menu **Clusters/_AZHOP - Cluster Shell Access** to open a shell window.
<img src="../images/clusters_shell_access_menu.png" width="75%">

Then submit a simple test job

```bash
qsub -l select=1:slot_type=hb60rs -- /usr/bin/bash -c 'sleep 60'
qstat
```

<img src="../images/shell_session_qsub_qstat.png" width="75%">
