# How to harden az-hop always running Virtual Machines

The Azure marketplace images used in `az-hop` are not hardened by default. This is fine if you want to run a demo or a prototype environemnt, but it's not when moving into production. While you can use your own hardened custom images for running all the `az-hop` infrastructure images, as we don't know how you configured your OS, you may have issues when running the install playbooks or when using the environment.
The current recipes provided in this folder are based on the CIS benchmarks, implemented as ansible playbooks located here [https://github.com/ansible-lockdown](https://github.com/ansible-lockdown). It's safe and tested to apply these rules once an environment have been installed.

## Clone repos
The `ansible-lockdown` github repos are not included in `az-hop` and need to be cloned in a dedicated folder in the deployer machine.

- clone RHEL7-CIS and RHEL8-CIS repos, each in their own directories

```bash
cd <repo_dir>
git clone https://github.com/ansible-lockdown/RHEL7-CIS.git
git clone https://github.com/ansible-lockdown/RHEL8-CIS.git
```

## Update playbooks
> Note: These updates are now integrated in the devel branch of these repos

Update task *Show Audit Summary* in file `<repo_dir>/RHEL7-CIS/tasks/main.yml` as follow :

```yml
- name: Show Audit Summary
  debug:
      msg: "{{ audit_results.split('\n') }}"
  when:
      - run_audit
  tags:
      - run_audit
```

In the file `<repo_dir>/RHEL8-CIS/tasks/main.yml` add the `run_audit` tag on tasks :
- pre_remediation_audit.yml
- post_remediation_audit.yml
- Show Audit Summary

For example : 
```yml
- import_tasks: post_remediation_audit.yml
  when:
  - run_audit
  tags:
  - run_audit
```

In the file `<repo_dir>/RHEL8-CIS/tasks/pre_remediation_audit.yml` update lines with `ansible_distribution_major_version == 7` and `ansible_distribution_major_version == 8` and add quotes around numbers `7` and `8`

For example :

```yml
- name: If using git for content set up
  block:
  - name: Install git (rh8 python3)
    package:
        name: git
        state: present
    when: ansible_distribution_major_version == '8'
```

## Set environment variables

Define both environment variables `CIS_PLAYBOOK_DIR_centos7` and `CIS_PLAYBOOK_DIR_centos8`

```bash
export CIS_PLAYBOOK_DIR_centos7=<repo_dir>/RHEL7-CIS
export CIS_PLAYBOOK_DIR_centos8=<repo_dir>/RHEL8-CIS
```

## Apply remediations
Applying remediations can be done by chuncks or all together with the helper script `harden.sh` located in the `<azhop_dir>/CIS` directory.

To apply hardening run these commands from the azhop root dir :

```bash
./CIS/harden.sh centos7 all
./CIS/harden.sh centos8 all
```

