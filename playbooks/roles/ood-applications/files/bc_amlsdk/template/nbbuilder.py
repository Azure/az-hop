import nbformat as nbf
import argparse


OUTPUT = "new1.ipynb"


def build_notebook(subscription, location, resourcegroup, workspace,
                   machinetype, maxinstances, jobfile, jobinputs):

    nb = nbf.v4.new_notebook()

    msg_welcome = """\
# AZHOP AzureML SDK (python) Entry point
Use this self-created template to run your parallel job in AzureML."""

    code_import = """\
import amlwrapperfunctions as aml"""

    code_login = """\
aml.login()"""

    code_setup_tmp = """\
aml.setupenv(subscription_id='{subscription}',
             location='{location}',
             resource_group='{resourcegroup}',
             workspace_name='{workspace}',
             machine_type='{machinetype}',
             max_instances={maxinstances})"""

    code_setup = code_setup_tmp.format(subscription=subscription,
                                       location=location,
                                       resourcegroup=resourcegroup,
                                       workspace=workspace,
                                       machinetype=machinetype,
                                       maxinstances=maxinstances)

    code_jobrun_tmp = """\
job_handler, aml_client = aml.runjob("{jobfile}", "{jobinputs}")"""

    code_jobrun = code_jobrun_tmp.format(jobfile=jobfile, jobinputs=jobinputs)

    code_jobstream = """\
aml_client.jobs.stream(job_handler.name)"""

    nb['cells'] = [nbf.v4.new_markdown_cell(msg_welcome),
                   nbf.v4.new_code_cell(code_import),
                   nbf.v4.new_code_cell(code_login),
                   nbf.v4.new_code_cell(code_setup),
                   nbf.v4.new_code_cell(code_jobrun),
                   nbf.v4.new_code_cell(code_jobstream)]

    nbf.write(nb, OUTPUT)


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--subscription",
                        help="Subscription", required=True)
    parser.add_argument("-l", "--location",
                        help="Location/region", required=True)
    parser.add_argument("-rg", "--resourcegroup",
                        help="Resource Group", required=True)
    parser.add_argument("-ws", "--workspace",
                        help="Workspace", required=True)
    parser.add_argument("-mt", "--machinetype",
                        help="Machine Type", required=True)
    parser.add_argument("-mi", "--maxinstances",
                        help="Max Instances", required=True)
    parser.add_argument("-j", "--jobfile",
                        help="Job File", required=True)
    parser.add_argument("-ji", "--jobinputs",
                        help="Job Inputs", required=True)

    args = parser.parse_args()
    subscription = args.subscription
    location = args.location
    resourcegroup = args.resourcegroup
    workspace = args.workspace
    machinetype = args.machinetype
    maxinstances = args.maxinstances
    jobfile = args.jobfile
    jobinputs = args.jobinputs

    build_notebook(subscription, location, resourcegroup, workspace,
                   machinetype, maxinstances, jobfile, jobinputs)


if __name__ == '__main__':
    main()
