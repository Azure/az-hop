#!/usr/bin/python3

import argparse
import os
import yaml
from jinja2 import Template


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Generate template file')
    parser.add_argument('-c', '--config-file', help='YAML config file', required=True)
    parser.add_argument('-i', '--input-dir', help='input directory ', required=True)
    parser.add_argument('-o', '--output', help='output file name', required=True)
    args = parser.parse_args()

    with open(args.config_file) as file:
        config = yaml.safe_load(file)

    btpl = [ 
        "parameters.bicep.j2",
        "nsg.bicep.j2",
        "network.bicep.j2",
        "asg.bicep.j2",
        "vms.bicep.j2",
        "anf.bicep.j2",
        "nfsfiles.bicep.j2",
        "sig.bicep.j2",
        "keyvault.bicep.j2",
        "secrets.bicep.j2",
        "storage.bicep.j2",
        "mysql.bicep.j2",
        "bastion.bicep.j2",
        "outputs.bicep.j2"
    ]

    with open(args.output, 'w') as ofile:
        
        for filename in btpl:
            with open(os.path.join(args.input_dir, filename)) as file:
                template = Template(file.read())

            ofile.write(template.render(config))
            ofile.write("\n")

