# Dotfiles

Ansible playbooks for desktop and server setup.

In i3, left-clicking a Dunst notification also focuses its sending app's window
and switches to that window's workspace. The notification workspace helper starts
with i3 and matches notification app names to window classes, using desktop files
where available. With multiple matching windows, it selects the most recently
focused one. Notifications without an identifiable open window or a Dunst history
entry retain their usual action. Right-click dismissal and notification expiry do
not switch workspaces.

```sh
ansible-galaxy collection install -r requirements.yml
ansible-playbook --connection=local --inventory=demewt, desktop.yml -K --user vlad --vault-id desktop_vault@prompt -e use_vault=true
ansible-playbook --connection=local --inventory=demewt, desktop.yml -K --user vlad --vault-id desktop_vault@~/.ansible/.desktop_vault_pass -e use_vault=true
ansible-playbook -K -i '<host>,' server.yml
```
