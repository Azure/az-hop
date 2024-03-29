import os
import random
import string
from os.path import exists
from azure.ai.ml import MLClient
from azure.identity import AzureCliCredential
from azure.ai.ml.entities import Workspace
from azure.ai.ml.entities import AmlCompute
from azure.ai.ml import command, MpiDistribution


class EnvSetup:
    subscription_id = ""
    location = ""
    resource_group = ""
    workspace_name = ""
    amlenv = ""
    machine_type = ""
    max_instances = ""
    ml_client = None
    workspace = None


envsetup = EnvSetup()


def get_random_string(length):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))


def login():

    print("Login into azure via browser")
    os.system("az login --output none")


def setupenv_ws():

    ml_client = MLClient(AzureCliCredential(),
                         envsetup.subscription_id, envsetup.resource_group)
    ws = Workspace(
        name=envsetup.workspace_name,
        location=envsetup.location,
        display_name="azhop aml sdk integration",
        description="This example shows azhop aml sdk integration",
        hbi_workspace=False,
        tags=dict(purpose="demo")
    )

    ws = ml_client.workspaces.begin_create(ws).result()
    # print(ws)

    return ws, ml_client


def setupenv_cluster():

    credential = AzureCliCredential()
    try:
        ml_client = MLClient.from_config(credential=credential)
    except Exception as ex:
        client_config = {
            "subscription_id": envsetup.subscription_id,
            "resource_group": envsetup.resource_group,
            "workspace_name": envsetup.workspace_name,
        }
        import json
        import os

        config_path = ".azureml/config.json"
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, "w") as fo:
            fo.write(json.dumps(client_config))
        ml_client = MLClient.from_config(
            credential=credential, path=config_path)

    gpu_compute_target = "gpu-cluster"

    try:
        ml_client.compute.get(gpu_compute_target)
    except Exception:
        print("Creating a new compute target...")
        compute = AmlCompute(
            name=gpu_compute_target,
            size=envsetup.machine_type,
            min_instances=0,
            max_instances=envsetup.max_instances
        )
        ml_client.compute.begin_create_or_update(compute).result()

    return ml_client


def setupenv(subscription_id, location, resource_group, workspace_name,
             amlenv, machine_type, max_instances):

    envsetup.subscription_id = subscription_id
    envsetup.location = location
    envsetup.resource_group = resource_group
    envsetup.workspace_name = workspace_name
    envsetup.amlenv = amlenv
    envsetup.machine_type = machine_type
    envsetup.max_instances = max_instances

    print("Setting up environment...")
    ws, ml_client = setupenv_ws()

    envsetup.workspace = ws
    envsetup.ml_client = ml_client

    ml_client = setupenv_cluster()
    envsetup.ml_client = ml_client

    print("Environment ready for job submission")


def runjob(filename, job_inputs):

    print("Job submitted to AzureML...")
    codedir = "./src/"

    full_command = "python "+filename+" "+job_inputs

    filename = codedir+filename
    if not exists(filename):
        print("Provided file does not exist:", filename)
        return None, None

    job_display_name = "azhop-aml-" + get_random_string(6)

    job = command(
        code=codedir,
        command=full_command,
        environment=envsetup.amlenv,
        compute="gpu-cluster",
        instance_count=envsetup.max_instances,
        distribution=MpiDistribution(process_count_per_instance=1),
        display_name=job_display_name
    )

    job_handler = envsetup.ml_client.create_or_update(job)

    if job_handler:
        print("Returning job handler to check its status. Job display name:",
              job_display_name)

    return job_handler, envsetup.ml_client
