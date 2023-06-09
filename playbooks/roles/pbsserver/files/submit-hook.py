# submit hook
# check if job environment variables doesn't contains single quotes, and if so reject the job

# To install run
# qmgr -c "create hook submit"
# qmgr -c "import hook submit application/x-python default submit-hook.py"
# qmgr -c "set hook submit event = queuejob"

import sys
import pbs
import subprocess

## Main program
try:
    je = pbs.event()
    jb = je.job

    for var in jb.Variable_List:
        quote = jb.Variable_List[var].find("'")
        if quote != -1:
            jb.Variable_List[var]="Value replaced by the PBS submit hook as it contains a quote"

    je.accept()

except SystemExit:
    pass

except:
   e=sys.exc_info()
   pbs.logmsg(pbs.LOG_DEBUG, "Error - type:  %s"%(e[0]))
   pbs.logmsg(pbs.LOG_DEBUG, "Error - value:  %s"%(e[1]))
   pbs.logmsg(pbs.LOG_DEBUG, "Error - traceback:  %s"%(e[2]))
   je.reject("Error submitting job in job submission hook! Contact your Admin")
