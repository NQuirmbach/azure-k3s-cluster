# Justfile manual 
# https://just.systems/man/en/
set dotenv-load
_default:
  just --list


# Create a new service-principal, add Contributor rights for resource-group and create app federation for github repo
identity-up:
  #!/usr/bin/env bash
  echo "Creating a new Azure AD Service Princiap & Role Assignment"
  subscription_id=$(just _get-subscription-id)

  echo "Creating service principal '$AZURE_APP_NAME'"
  app_id=$(az ad sp create-for-rbac --name "$AZURE_APP_NAME" \
    --role "$AZURE_CLIENT_ROLE" \
    --scopes "/subscriptions/$subscription_id" \
    --query "appId" -o tsv)

  just _create-app-federations $app_id
  echo "All done"

# Deletes the existing app federation
_create-app-federations app_id:
  #!/usr/bin/env bash
  echo "Creating app federations for app {{ app_id }}"

  for env in $GITHUB_ENVIRONMENTS; do
    az ad app federated-credential create \
        --id "{{ app_id }}" \
        --parameters "{\"name\":\"GitHubActionsEnv-$env\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_REPO:environment:$env\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

    az ad app federated-credential create \
        --id "{{ app_id }}" \
        --parameters "{\"name\":\"GitHubActionsBranch-$env\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_REPO:ref:refs/heads/$env\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
    
    echo "Created app federation for environment $env"
  done

# Deletes the federated identity, role assignment and service-principal
identity-destroy:
  #!/usr/bin/env bash
  subscription_id=$(just _get-subscription-id)
  app_id=$(just _get-app-id)
  
  if [[ -z "${app_id}" ]]; then
    echo "No app regirstation with name $AZURE_APP_NAME found. Exit"
    exit 0
  fi

  principal_id=$(az ad sp list --filter "appId eq '$app_id'"  --query "[].id" -o tsv)
  just _delete-app-federations $app_id

  echo "Removing role assignment..."
  az role assignment delete --assignee "$app_id" --scope "/subscriptions/$subscription_id"

  echo "Deleting app"
  az ad app delete --id "$app_id"
  echo "All done!"


# Deletes the existing app federation
_delete-app-federations app_id:
  #!/usr/bin/env bash
  echo "Deleting app federation for app {{ app_id }}"
  federated_ids=$(az ad app federated-credential list --id "{{ app_id }}" --query "[].id" -o tsv)

  if [[ -z "${federated_ids}" ]]; then
    exit
  fi

  for credential_id in $federated_ids; do
    az ad app federated-credential delete \
      --id "{{ app_id }}" \
      --federated-credential-id "$credential_id"
  done
  echo "Deleted all app federations"

# Show all debug info
debug:
  az ad app list --filter "displayName eq '$AZURE_APP_NAME'" -o table
  az ad sp list --display-name "$AZURE_APP_NAME" -o table
  just _get-app-federations

_get-app-federations:
  #!/usr/bin/env bash
  app_id=$(just _get-app-id)
  az ad app federated-credential list --id "$app_id"

_get-app-id:
  az ad sp list --display-name "$AZURE_APP_NAME" --query "[].appId" -o tsv

_get-subscription-id:
  az account show --query "id" -o tsv