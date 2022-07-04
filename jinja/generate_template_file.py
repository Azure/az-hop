#!/usr/bin/python3

import glob
import os
import yaml
from jinja2 import Template

input_yml = {}

with open("config.yml") as file:
    input_yml['config'] = yaml.safe_load(file)
with open("access.yml") as file:
    input_yml['access'] = yaml.safe_load(file)
with open("outputs.yml") as file:
    input_yml['outputs'] = yaml.safe_load(file)

input_yml['keys'] = {}
with open(input_yml['outputs']['admin_user']+'_id_rsa.pub') as file:
    input_yml['keys']['ssh_public_key'] = file.read()

input_yml['admin_password'] = os.environ['admin_pass']
input_yml['azhop_root'] = os.environ['azhop_root']

for filepath in glob.iglob('templates/*.j2'):
    print(filepath)
    with open(filepath) as file:
        template = Template(file.read())
    with open(filepath[:-3], 'w') as file:
        file.write(template.render(input_yml))

