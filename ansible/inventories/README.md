# Inventaires Ansible

Chaque environnement a son dossier :

| Fichier | Origine | Commité ? |
|---|---|---|
| `<env>/hosts.yml` | **Généré par Terraform** (IP de la VM) | Non (`.gitignore`) |
| `<env>/group_vars/all/terraform.yml` | **Généré par Terraform** (domaine, FQDN, NSG...) | Non |
| `<env>/group_vars/all/main.yml` | Écrit à la main (choix propres à l'environnement) | Oui |

En CI, les fichiers générés sont recréés à chaque run par `terraform output`.
En local : `terraform -chdir=terraform/<env> apply` les écrit sur disque.
