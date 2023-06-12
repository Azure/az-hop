#!/usr/bin/python3
# Configure Cycle to use Active Directory for Auth
import sys
import os
import argparse
import json
from shutil import rmtree, copy2, move
from subprocess import CalledProcessError, check_output
from os import path, listdir, chdir, fdopen, remove
from tempfile import mkstemp, mkdtemp

cycle_root = "/opt/cycle_server"
tmpdir = mkdtemp()
print("Creating temp directory {} for installing CycleCloud".format(tmpdir))

def clean_up():
    rmtree(tmpdir)

def _catch_sys_error(cmd_list):
    try:
        output = check_output(cmd_list)
        print(cmd_list)
        print(output)
        return output
    except CalledProcessError as e:
        print("Error with cmd: %s" % e.cmd)
        print("Output: %s" % e.output)
        raise

def create_ad_settings(url, domain):
    authenticator = {
        "AdType": "Application.Authenticator",
        "DefaultDomain": domain,
        "Disabled": False,
        "Label": "Active Directory",
        "Method": "active_directory",
        "Name": "active_directory",
        "Order": 100,
        "URL": url
    }
    app_setting_installation = {
        "AdType": "Application.Setting",
        "Name": "authorization.check_datastore_permissions",
        "Value": True
    }
    configure_ad_data = [
        authenticator,
        app_setting_installation
    ]
    data_file = os.path.join(tmpdir, "configure_ad.json")
    print("Creating record file: {}".format(data_file))
    with open(data_file, 'w') as fp:
        json.dump(configure_ad_data, fp)

    config_path = os.path.join(cycle_root, "config/data/")
    print("Copying config to {}".format(config_path))
    copy2(data_file, config_path)

def main():
    parser = argparse.ArgumentParser(description="usage: %prog [options]")
    parser.add_argument("--url",
                        dest="url",
                        help="The ldap url to connect to aka: ldap(s)://domainserver")
    parser.add_argument("--domain",
                        dest="domain",
                        help="The domain name")
    args = parser.parse_args()

    print("Debugging arguments: %s" % args)
    create_ad_settings(args.url, args.domain)
    clean_up()

if __name__ == "__main__":
    try:
        main()
    except:
        sys.exit("Deployment failed...")
