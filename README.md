# Dotfiles

Ansible playbooks for desktop and server setup.

```sh
ansible-galaxy collection install -r requirements.yml
ansible-playbook --connection=local --inventory=demewt, desktop.yml -K --user vlad --vault-id desktop_vault@prompt -e use_vault=true
ansible-playbook --connection=local --inventory=demewt, desktop.yml -K --user vlad --vault-id desktop_vault@~/.ansible/.desktop_vault_pass -e use_vault=true
ansible-playbook -K -i '<host>,' server.yml
```
