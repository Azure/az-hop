# enroot hook
# create and delete temporary directories needed for enroot containers per job
#
# Adapted from https://community.altair.com/community?id=kb_article_view&sysparm_article=KB0116653&sys_kb_id=cb907192dbd43414e8863978f4961913&spa=1

# To install run
# qmgr -c "create hook enroot"
# qmgr -c "set hook enroot enabled = true"
# qmgr -c "set hook enroot event = execjob_prologue"
# qmgr -c "set hook enroot event += execjob_end"
# qmgr -c "set hook enroot alarm = 30"
# qmgr -c "set hook enroot order = 1"
# qmgr -c "import   hook    enroot    application/x-python    default    enroot.PY"

import os,sys
import pbs
import shutil

e=pbs.event()
j=e.job
j_id=j.id

if "enroot" in j.Variable_List:
    val=str(j.Variable_List['enroot'])
    if val == "1":
        pbs.logmsg(pbs.LOG_DEBUG, "enroot request value is %s" % str(val))
        who=j.Job_Owner.split('@')[0]
        root_dir="/mnt/resource/pbs"
        runtime_path=root_dir+"/enroot/user-" + str(j_id)
        cache_path=root_dir+"/enroot-cache/group-" + str(j_id)
        data_path=root_dir+"/enroot-data/user-" + str(j_id)

        # Create directory on job prolog
        if pbs.event().type == pbs.EXECJOB_PROLOGUE and j.in_ms_mom():
            print("ENROOT_RUNTIME_PATH="+runtime_path,sys.stderr)
            print("ENROOT_CACHE_PATH="+cache_path,sys.stderr) 
            print("ENROOT_DATA_PATH="+data_path,sys.stderr)
            os.makedirs(runtime_path,0o700)
            os.makedirs(cache_path,0o700)
            os.makedirs(data_path,0o700)
            change_perm="chmod 1777 " + root_dir +"/enroot " + root_dir+ "/enroot-cache " + root_dir+"/enroot-data "
            os.system(change_perm)
            change_owner="chown " + who + " "+ runtime_path +" "+ cache_path +" " +data_path
            os.system(change_owner)

        # Delete directories on job end
        if pbs.event().type == pbs.EXECJOB_END and j.in_ms_mom():
            if os.path.isdir(runtime_path) and "enroot" in runtime_path: 
                pbs.logmsg(pbs.LOG_DEBUG,"<========From excejob_end Hook, runtime_path dir is ========>> (%s)" %runtime_path)
                shutil.rmtree(runtime_path)
            if os.path.isdir(cache_path) and "enroot" in cache_path: 
                shutil.rmtree(cache_path)
            if os.path.isdir(data_path) and "enroot" in data_path: 
                shutil.rmtree(data_path)
