Import-Function Get-TenantPackage

$tenantItem = Get-Item .
Get-TenantPackage $tenantItem > $null