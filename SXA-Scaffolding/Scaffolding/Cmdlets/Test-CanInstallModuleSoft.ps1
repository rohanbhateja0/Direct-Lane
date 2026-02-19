function Test-CanInstallModuleSoft {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,
            
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Test-CanInstallModuleSoft - Begin"
        Import-Function Get-ModuleActionItem
        Import-Function Test-ActionIntegrity
        Import-Function Get-TenantItem
    }

    process {
        Write-Verbose "Processing $($Site.Name) site"
        $tenant = Get-TenantItem $Site
        $invokedSiteActions = Get-ModuleActionItem $Site
        $invokedTenantActions = Get-ModuleActionItem $tenant
        $invokedActions = $invokedTenantActions + $invokedSiteActions
        
        Test-ActionIntegrity $Site $DefinitionItems $invokedActions
    }

    end {
        Write-Verbose "Cmdlet Test-CanInstallModuleSoft - End"
    }
}