# 🏗️ Cocktail Infra

Infrastructure as Code de l'application Cocktail : **Terraform** (Azure) + **Ansible**, pilotés par **GitHub Actions**.
Ce dépôt est appelé par la CI de `cocktail-app` via des **workflows réutilisables** versionnés (`@v1`).

## Environnements

| Environnement | VM | Cycle de vie | Workflow |
|---|---|---|---|
| Staging | `vm-cocktail-staging` (B2s) | Créé à chaque release, détruit après la mise en prod et **chaque jour à 17h** | `staging-up.yml` / `staging-down.yml` |
| Production | `vm-cocktail-prod` (B2s) | Permanent, reprise après sinistre par workflow | `prod-provision.yml` + `deploy.yml` |
| Supervision | `vm-cocktail-monitoring` (B4ms) | Permanent : Wazuh + Grafana/Loki/Prometheus | `monitoring-provision.yml` |

## Arborescence

```
terraform/
  modules/vm/        VM Ubuntu 24.04 + réseau + NSG + IP publique statique
  staging/           state staging.tfstate
  production/        state production.tfstate (+ droit d'écriture des sauvegardes)
  monitoring/        state monitoring.tfstate
  templates/         modèle d'inventaire Ansible
ansible/
  playbooks/         provision-app-host, deploy, monitoring, restore, wazuh-*
  roles/             common, docker, app, alloy, wazuh_agent, wazuh_manager, monitoring_stack, backup
  inventories/<env>/ hosts.yml et terraform.yml GÉNÉRÉS par Terraform
bootstrap/           script Azure à lancer une seule fois (state, sauvegardes, OIDC)
.github/
  actions/           setup-infra, ssh-access, ansible-inventory
  workflows/         staging-up, staging-down, deploy, prod-provision, monitoring-provision, restore-test, ci
```

## Versionner le contrat avec cocktail-app

`cocktail-app` appelle `...@v1`. Après une évolution compatible du dépôt infra :

```bash
git tag -f v1 && git push -f origin v1
```

Une évolution **incompatible** (entrées de workflow renommées...) donne un nouveau tag `v2`, et `cocktail-app` migre quand il est prêt.

Le pas-à-pas complet est dans `GUIDE-MISE-EN-PLACE.md` (dépôt cocktail-app).
