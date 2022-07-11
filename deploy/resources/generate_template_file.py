#!/usr/bin/python3

import argparse
import glob
import os
import yaml
from jinja2 import Template

if __name__ == "__main__":

    input_yml = {}

    with open("build.yml") as file:
        input_yml['config'] = yaml.safe_load(file)
    with open("outputs.yml") as file:
        input_yml['outputs'] = yaml.safe_load(file)

    with open(os.path.join(os.environ['azhop_root'], input_yml['outputs']['admin_user']+'_id_rsa.pub')) as file:
        input_yml['ssh_public_key'] = file.read()

    input_yml['admin_password'] = os.environ['admin_pass']
    input_yml['azhop_root'] = os.environ['azhop_root']

    # use argparse to get input and output file name
    parser = argparse.ArgumentParser(description='Generate template file')
    parser.add_argument('-i', '--input', help='input file name', required=True)
    parser.add_argument('-o', '--output', help='output file name', required=True)
    args = parser.parse_args()

    # read input file
    with open(args.input) as file:
        template = Template(file.read())

    # render template
    with open(args.output, 'w') as file:
        file.write(template.render(input_yml))

    print("Template file generated: " + args.output)


