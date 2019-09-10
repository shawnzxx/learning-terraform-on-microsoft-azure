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