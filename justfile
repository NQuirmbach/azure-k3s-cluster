# Justfile manual 
# https://just.systems/man/en/
set dotenv-load
_default:
  just --list

# Does all the initial work for you
init: create-resource-group create-federated-identity

# Deletes service-principal, assignemnts and resource-group
destroy: delete-federated-identity delete-resource-group

# Create a new azure resource group for this example
create-resource-group:
  az account show
  az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"

# Delete the existing resource group
delete-resource-group:
  az group delete --name "$AZURE_RESOURCE_GROUP"

# Create a new service-principal, add Contributor rights for resource-group and create app federation for github repo
create-federated-identity:
  #!/usr/bin/env bash
  echo "Creating a new Azure AD Service Princiap & Role Assignment"
  subscription_id=$(az account show --query "id" -o tsv)
  app_id=$(az ad sp create-for-rbac --name "$AZURE_APP_NAME" --query "appId" -o tsv)

  echo "Creating role assignment for app $AZURE_APP_NAME"

  az role assignment create --assignee "$app_id" --role "$AZURE_CLIENT_ROLE" \
    --scope "/subscriptions/$subscription_id/resourceGroups/$AZURE_RESOURCE_GROUP"

  echo "Creating federated identity"
  az ad app federated-credential create \
      --id "$app_id" \
      --parameters "{\"name\":\"GitHubActions\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_REPO:ref:refs/heads/*\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

  az ad app federated-credential create \
      --id "$app_id" \
      --parameters "{\"name\":\"GitHubActionsFeature\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_REPO:ref:refs/heads/feature/*\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

  az ad sp list --display-name "$AZURE_APP_NAME"
  echo "All done"

# Deletes the federated identity, role assignment and service-principal
delete-federated-identity:
  #!/usr/bin/env bash
  principal_id=$(just _get-sp-prop "id")
  app_id=$(az ad app list --filter "displayName eq '$AZURE_APP_NAME'" --query '[].id' -o tsv)
  
  if [[ -z "${principal_id}" ]]; then
    echo "No service principal with name $AZURE_APP_NAME found. Skipping"
    exit
  fi

  just delete-app-federation

  echo "Removing role assignment..."
  az role assignment delete --assignee "$principal_id" --resource-group "$AZURE_RESOURCE_GROUP"

  echo "Deleting service principal & app..."
  az ad sp delete --id "$principal_id"
  az ad app delete --id "$app_id"

  echo "All done!"


# Deletes the existing app federation
delete-app-federation:
  #!/usr/bin/env bash
  echo "Deleting app federation"
  app_id=$(just _get-sp-prop "appId")
  federated_ids=$(az ad app federated-credential list --id "$app_id" --query "[].id" -o tsv)

  if [[ -z "${federated_ids}" ]]; then
    exit
  fi

  for credential_id in $federated_ids; do
    az ad app federated-credential delete \
      --id "$app_id" \
      --federated-credential-id "$credential_id"
  done

  echo "Deleted all app federations"

# Show all federations for the app
get-app-federations:
  #!/usr/bin/env bash
  app_id=$(just _get-sp-prop "appId")
  az ad app federated-credential list --id "$app_id"

# Show all federations for the app
get-principal:
  az ad sp list --display-name "$AZURE_APP_NAME"

_get-sp-prop prop:
  az ad sp list --display-name "$AZURE_APP_NAME" --query "[].{{ prop }}" -o tsv