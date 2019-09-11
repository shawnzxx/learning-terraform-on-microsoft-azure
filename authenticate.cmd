
REM Install and configure Terraform
REM https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure#code-try-3
REM get a list of subscription ID and tenant ID
az account list --query "[].{name:name, subscriptionId:id, tenantId:tenantId}"
[
  {
    "name": "Visual Studio Ultimate with MSDN",
    "subscriptionId": "cd43fc17-54a5-4a34-903b-8d10dd2c8330",
    "tenantId": "ca7b1c60-872a-4cf6-98e5-2f75cab29474"
  }
]
REM set the subscription for this session
az account set --subscription="${SUBSCRIPTION_ID}"
REM create a service principal for use with Terraform
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"

----------------------------------------------------------------------------------------------

REM login az cli using system env
az login --service-principal -u %TF_VAR_client_id% -p %TF_VAR_client_secret% -t %TF_VAR_tenant_id%

REM list out all offers from publisher MicrosoftWindowsServer
az vm image list-offers -l southeastasia -p MicrosoftWindowsServer -o table

REM list all sku from offer WindowsServer
az vm image list-skus -l southeastasia -p MicrosoftWindowsServer -f WindowsServer -o table

REM list all vm size
az vm list-sizes -l southeastasia -o table

REM list all extension images of vm
az vm extension image list -l southeastasia -o table
az vm extension image list-names -l southeastasia -p Microsoft.Compute -o table

output:
Location       Name
-------------  ---------------------
southeastasia  BGInfo
southeastasia  CustomScriptExtension
southeastasia  JsonADDomainExtension
southeastasia  VMAccessAgent

REM check version
az vm extension image list-versions -l southeastasia -p Microsoft.Compute -n CustomScriptExtension -o table