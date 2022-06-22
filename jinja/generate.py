#!/usr/bin/python3

import yaml
from jinja2 import Template

with open("config.yml") as file:
    config = yaml.safe_load(file)

with open("azhop.bicep.j2") as file:
    template = Template(file.read())

print(template.render(config))

