# Add Users
Adding users is done in four steps :
- Update your `config.yml` file
- run the `create_passwords.sh` script
- run the `add_users` Ansible playbook
- run the `cccluster` playbook to update the Cycle project files

You can specify in which groups users belongs to but at least they are all in the `Domain Users (gid: 5000)` domain group. By default there are built-in groups you can't change names otherwise things will break :
- `Domain Users` : All users will be added to this one by default
- `az-hop-admins` :  For users with azhop admin privileges like starting/stopping nodes or editing grafana dashboards
- `az-hop-localadmins` : For users with Linux sudo right or Windows localadmin right on compute or viz nodes
## Add users in the configuration file

Open the configuration file used to deploy your environment and add new users in the `users` dictionary, and configure `usergroups` like below :

```yml
users:
  - { name: hpcuser,   uid: 10001, groups: [6000] }
  - { name: adminuser, uid: 10002, groups: [5001, 5002, 6000, 6001] }
  - { name: user1, uid: 10004, groups: [6000] }
  - { name: user2, uid: 10005, groups: [6001] }

usergroups:
  - name: Domain Users # All users will be added to this one by default
    gid: 5000
  - name: az-hop-admins # For users with azhop admin privilege
    gid: 5001
    description: "For users with azhop admin privileges"
  - name: az-hop-localadmins # For users with sudo right on nodes
    gid: 5002
    description: "For users with sudo right or local admin right on nodes"
  - name: project1 # For project1 users
    gid: 6000
    description: Members of project1
  - name: project2 # For project2 users
    gid: 6001
    description: Members of project2
```

## Create users passwords

Run the `create_passwords.sh` scripts. This will create a password for each new users, and store it in the key vault deployed in this environment, under the secret named `<user>-password`

```bash
$./create_passwords.sh
```

## Add users to the system

Run the `add_users` Ansible playbook to create these users in the Domain and generate their SSH keys.

```bash
$./install.sh add_users
```

## Update the Cycle project files

```bash
$./install.sh cccluster
```
