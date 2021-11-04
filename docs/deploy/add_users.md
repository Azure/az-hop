# Add Users
Adding users is done in four steps :
- Update your `config.yml` file
- run the `create_passwords.sh` script
- run the `add_users` Ansible playbook
- run the `cccluster` playbook to update the Cycle project files


## Add users in the configuration file

Open the configuration file used to deploy your environment and add new users in the `users` dictionnary like below :

```yml
users:
  - { name: user1, uid: 10001, gid: 5000, admin: true, sudo: true }
  - { name: user2, uid: 10002, gid: 5000 }
```

## Create users passwords

Run the `create_passwords.sh` scripts. This will create a password for each new users, and store it in the keyvault deployed in this environemnt, under the secret named `<user>-password`

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
