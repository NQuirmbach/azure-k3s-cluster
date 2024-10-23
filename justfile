# Justfile manual 
# https://just.systems/man/en/

set dotenv-load

_default:
  just --list

# Create a new azure resource group for this example
create-az-resource-group:
  az account show
  az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"

delete-az-resource-group:
  az account show
  az group show --name "$AZURE_RESOURCE_GROUP"
  az group delete --name "$AZURE_RESOURCE_GROUP"

create-az-federated-identity:
  #!/usr/bin/env bash
  echo "Creating a new Azure AD Service Princiap & Role Assignment"

  subscription_id=$(az account show --query "id" -o tsv)
  app_id=$(az ad sp create-for-rbac --name "$AZURE_APP_NAME" --query "appId" -o tsv)

  echo "Creating role assignment for app $app_id"
  az role assignment create --assignee "$app_id" --role "$AZURE_CLIENT_ROLE" \
    --scope "/subscriptions/$subscription_id/resourceGroups/$AZURE_RESOURCE_GROUP"

  echo "Creating federated identity"
  az ad app federated-credential create \
      --id "$app_id" \
      --parameters "{\"name\":\"GitHubActions\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_REPO:ref:refs/heads/$BRANCH_NAME\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

  echo "All done"


delete-az-federated-identity:
  #!/usr/bin/env bash
  echo "Removing existing Azure AD App"
  app_id=$(az ad sp list --filter "displayName eq '$AZURE_APP_NAME'" --query "[].id" -o tsv)
  
  if [[ -z "${app_id}" ]]; then
    echo "No app with name $AZURE_APP_NAME found. Skipping"
    exit
  fi

  echo "Found app with id $app_id"
  echo "Removing role assignment..."
  az role assignment delete --assignee "$app_id" --resource-group "$AZURE_RESOURCE_GROUP"

  echo "Deleting service principal..."
  az ad sp delete --id "$app_id"

  echo "All done!"