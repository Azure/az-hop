# Add Users
Adding users is done in three steps :
- Update your `config.yml` file
- run the `create_passwords.sh` script
- run the `add_users` Ansible playbook


## Add users in the configuration file

Open the configuration file used to deploy your environment and add new users in the `users` dictionnary like below :

```yml
users:
  - name: user1
    uid: 10001
    gid: 5000
    shell: /bin/bash
    home: /anfhome/user1
    admin: false
    sudo: true
  - name: user2
    uid: 10002
    gid: 5000
    shell: /bin/bash
    home: /anfhome/user2
    admin: false
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

