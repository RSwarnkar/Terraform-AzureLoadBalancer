

## Create Service Principal (Client ID and Clinet Secret) to be used: 

# Step-1 : Login via Global-Admin:

## Change Tenant and Subscription ID if needed
$TENANT_ID       = "<Your Tenant ID here>" 
$SUBSCRIPTION_ID = "<Your Subscription ID Here>"

Write-Host "Connecting..."
Connect-AzAccount -Tenant $TENANT_ID -UseDeviceAuthentication -SubscriptionId $SUBSCRIPTION_ID

Set-AzContext -SubscriptionId $SUBSCRIPTION_ID


# Step-2 : Create Service Principal: 

$adate = Get-Date -Format "yyyyMMM"

# Variables 
$servicePrincipalName = "sp4tf-${adate}-$(-join ((97..122) | Get-Random -Count 5 | % {[char]$_}))"

$scope = "/subscriptions/$($SUBSCRIPTION_ID)/"

# https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
$role_name = "Owner"

Write-Host "Attempting to create new Service Principal: $($servicePrincipalName)"

$sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName 

$display_name  = $sp.DisplayName 
$client_id     = $sp.AppId # Application (Client ID) 
$client_secret = $sp.PasswordCredentials.SecretText  # Application (Client) Secret 
$object_id     = $sp.Id # Object ID 

Write-Host "Attempting to assign RBAC role to new Service Principal: $($servicePrincipalName)"

New-AzRoleAssignment -ApplicationId $client_id -RoleDefinitionName $role_name -Scope $scope


Write-Host "=============================================================="
Write-Host "Service Principal Details: "
Write-Host "=============================================================="


Write-Host "`$env:ARM_CLIENT_ID       = `"$($client_id)`""
Write-Host "`$env:ARM_CLIENT_SECRET   = `"$($client_secret)`""
Write-Host "`$env:ARM_SUBSCRIPTION_ID = `"$($SUBSCRIPTION_ID)`""
Write-Host "`$env:ARM_TENANT_ID       = `"$($TENANT_ID)`""


Write-Host "`$SP_ClientID     = `$env:ARM_CLIENT_ID`n`$SP_SubID        = `$env:ARM_SUBSCRIPTION_ID`n`$SP_ClientSecret = ConvertTo-SecureString `$env:ARM_CLIENT_SECRET -AsPlainText -Force`n`$SP_Credential   = New-Object System.Management.Automation.PSCredential(`$SP_ClientID , `$SP_ClientSecret)`nConnect-AzAccount -Credential `$SP_Credential -Tenant `$env:ARM_TENANT_ID -ServicePrincipal`nSet-AzContext -SubscriptionId `$SP_SubID`n"

Write-Host "=============================================================="

