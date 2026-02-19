function Test-CanInstallSiteModuleHard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,
            
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Test-CanInstallSiteModuleHard - Begin"
        Import-Function Get-InvokedSiteAction
        Import-Function Get-InvokedTenantAction
        Import-Function Get-TenantTemplatesRoot
        Import-Function Get-TenantTemplate
        Import-Function Get-TenantItem
        Import-Function Test-ActionIntegrity
    }

    process {        
        $tenantTemplateRoot = Get-TenantTemplatesRoot $Site
        $tenantTemplates = Get-TenantTemplate $tenantTemplateRoot      
        $tenant = Get-TenantItem $Site

        $invokedSiteActions = Get-InvokedSiteAction $tenantTemplates $Site
        $invokedTenantActions = Get-InvokedTenantAction $tenantTemplates $tenant
        $invokedActions = $invokedTenantActions + $invokedSiteActions
        
        Test-ActionIntegrity $Site $DefinitionItems $invokedActions
    }

    end {
        Write-Verbose "Cmdlet Test-CanInstallSiteModuleHard - End"
    }
}