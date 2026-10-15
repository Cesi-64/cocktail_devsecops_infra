#!/usr/bin/env bash
# =====================================================================
# Bootstrap Azure - à lancer UNE SEULE FOIS, à la main, avant toute CI.
#
# Crée ce que Terraform ne peut pas créer pour lui-même ("la poule et l'œuf") :
#   - le compte de stockage du state Terraform ;
#   - le compte de stockage des sauvegardes (doit survivre à la prod) ;
#   - l'identité Azure utilisée par GitHub Actions, en OIDC (aucun secret) ;
#   - les droits de cette identité.
#
# Prérequis : az CLI connecté (az login) avec un compte Owner de l'abonnement.
# Usage :
#   export GITHUB_ORG=mon-orga            # nom EXACT (majuscules comprises)
#   export DNS_ZONE=cocktail.mon-ecole.fr # zone Azure DNS existante
#   export DNS_ZONE_RG=rg-dns             # son groupe de ressources
#   ./bootstrap/bootstrap.sh
# =====================================================================
set -euo pipefail

GITHUB_ORG="${GITHUB_ORG:?export GITHUB_ORG=<organisation GitHub>}"
DNS_ZONE="${DNS_ZONE:?export DNS_ZONE=<zone Azure DNS>}"
DNS_ZONE_RG="${DNS_ZONE_RG:?export DNS_ZONE_RG=<groupe de ressources de la zone>}"
LOCATION="${LOCATION:-francecentral}"
SHARED_RG="${SHARED_RG:-rg-cocktail-shared}"
SUFFIX="${SUFFIX:-$(openssl rand -hex 3)}"          # noms de stockage uniques au monde
TFSTATE_SA="sttfcocktail${SUFFIX}"
BACKUP_SA="stbkcocktail${SUFFIX}"
APP_NAME="${APP_NAME:-gh-cocktail-deployer}"

SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
ME=$(az ad signed-in-user show --query id -o tsv)

step() { echo; echo "==> $*"; }

step "Vérification de la zone DNS ${DNS_ZONE}"
az network dns zone show -g "${DNS_ZONE_RG}" -n "${DNS_ZONE}" -o none

step "Groupe de ressources partagé ${SHARED_RG}"
az group create -n "${SHARED_RG}" -l "${LOCATION}" --tags project=cocktail managed_by=bootstrap -o none

create_sa() {
  local name=$1
  az storage account create -n "${name}" -g "${SHARED_RG}" -l "${LOCATION}" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
    --allow-blob-public-access false --allow-shared-key-access false \
    --tags project=cocktail -o none
  az storage account blob-service-properties update --account-name "${name}" -g "${SHARED_RG}" \
    --enable-versioning true --enable-delete-retention true --delete-retention-days 30 \
    --enable-container-delete-retention true --container-delete-retention-days 30 -o none
  # Votre compte doit avoir un rôle "données" pour créer le conteneur (pas de clé de compte)
  az role assignment create --assignee-object-id "${ME}" --assignee-principal-type User \
    --role "Storage Blob Data Contributor" \
    --scope "$(az storage account show -n "${name}" -g "${SHARED_RG}" --query id -o tsv)" -o none
}

step "Compte de stockage du state Terraform ${TFSTATE_SA}"
create_sa "${TFSTATE_SA}"

step "Compte de stockage des sauvegardes ${BACKUP_SA}"
create_sa "${BACKUP_SA}"

step "Attente de la propagation des droits (60 s)"
sleep 60

az storage container create --name tfstate --account-name "${TFSTATE_SA}" --auth-mode login -o none
az storage container create --name mariadb --account-name "${BACKUP_SA}" --auth-mode login -o none

step "Rétention des sauvegardes : suppression automatique après 30 jours"
cat > /tmp/cocktail-backup-policy.json <<'JSON'
{
  "rules": [
    {
      "enabled": true,
      "name": "expire-backups-30d",
      "type": "Lifecycle",
      "definition": {
        "actions": { "baseBlob": { "delete": { "daysAfterModificationGreaterThan": 30 } } },
        "filters": { "blobTypes": ["blockBlob"], "prefixMatch": ["mariadb/"] }
      }
    }
  ]
}
JSON
az storage account management-policy create --account-name "${BACKUP_SA}" -g "${SHARED_RG}" \
  --policy @/tmp/cocktail-backup-policy.json -o none

step "Identité de déploiement ${APP_NAME} (Entra ID)"
APP_ID=$(az ad app list --display-name "${APP_NAME}" --query '[0].appId' -o tsv)
if [ -z "${APP_ID}" ]; then
  APP_ID=$(az ad app create --display-name "${APP_NAME}" --query appId -o tsv)
  az ad sp create --id "${APP_ID}" -o none
  sleep 20
fi
SP_ID=$(az ad sp show --id "${APP_ID}" --query id -o tsv)

step "Fédération OIDC GitHub -> Azure (un sujet par dépôt et par environnement)"
for pair in cocktail-infra:staging cocktail-infra:production cocktail-infra:monitoring \
            cocktail-app:staging cocktail-app:production; do
  repo="${pair%%:*}"; env="${pair##*:}"
  name="gh-${repo}-${env}"
  if az ad app federated-credential show --id "${APP_ID}" --federated-credential-id "${name}" -o none 2>/dev/null; then
    echo "   ${name} existe déjà"; continue
  fi
  az ad app federated-credential create --id "${APP_ID}" -o none --parameters "{
    \"name\": \"${name}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${repo}:environment:${env}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
  echo "   ${name} -> repo:${GITHUB_ORG}/${repo}:environment:${env}"
done

step "Droits de l'identité de déploiement"
assign() { az role assignment create --assignee-object-id "${SP_ID}" --assignee-principal-type ServicePrincipal \
  --role "$1" --scope "$2" -o none && echo "   $1"; }
TFSTATE_ID=$(az storage account show -n "${TFSTATE_SA}" -g "${SHARED_RG}" --query id -o tsv)
BACKUP_ID=$(az storage account show -n "${BACKUP_SA}" -g "${SHARED_RG}" --query id -o tsv)
# Contributor sur l'abonnement : crée les groupes de ressources et les enregistrements DNS.
# (Dans une vraie entreprise on le restreindrait à des groupes de ressources précis.)
assign "Contributor" "/subscriptions/${SUB_ID}"
assign "Storage Blob Data Contributor" "${TFSTATE_ID}"          # lire/écrire le state
assign "Storage Blob Data Reader" "${BACKUP_ID}"                # télécharger les sauvegardes (restauration)
assign "Role Based Access Control Administrator" "${BACKUP_ID}" # donner à la VM de prod le droit d'écrire ses sauvegardes

cat <<SUMMARY

=====================================================================
 Bootstrap terminé. Variables à créer dans l'organisation GitHub
 (Settings > Secrets and variables > Actions > Variables) :
=====================================================================
 AZURE_CLIENT_ID          = ${APP_ID}
 AZURE_TENANT_ID          = ${TENANT_ID}
 AZURE_SUBSCRIPTION_ID    = ${SUB_ID}
 TFSTATE_RESOURCE_GROUP   = ${SHARED_RG}
 TFSTATE_STORAGE_ACCOUNT  = ${TFSTATE_SA}
 BACKUP_STORAGE_ACCOUNT   = ${BACKUP_SA}
 DOMAIN                   = ${DNS_ZONE}
 DNS_ZONE_RESOURCE_GROUP  = ${DNS_ZONE_RG}
=====================================================================
SUMMARY
