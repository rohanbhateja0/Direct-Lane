function Install-TenantModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$tenantSetup,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$tenants
    )

    begin {
        Write-Verbose "Cmdlet Install-TenantModule - Begin"
        Import-Function Add-TenantModule
        Import-Function Show-TenantSelectionDialog
        Import-Function Get-ItemWithoutModuleInstalled
    }

    process {
        $tenantsWithoutModule = Get-ItemWithoutModuleInstalled $tenants $tenantSetup

        if ($tenantsWithoutModule.Count -eq 0) {
            Show-Alert ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThereAreNoTenantsWithoutThisModule))
            Exit
        }
        $dTitle = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddTenantModuleTitle)
        $dDescription = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddTenantModuleDescription) -f $tenantSetup.Fields["Name"].Value)
        $tenantsWithoutModule = Show-TenantSelectionDialog $tenantsWithoutModule -DialogTitle $dTitle -DialogDescription $dDescription

        $tenantsWithoutModule | % {
            $tenant = $_
            Write-Host "Extending '$($tenant.Name)' site collection modules"
            Add-TenantModule $tenant $tenantSetup
        }
    }

    end {
        Write-Verbose "Cmdlet Install-TenantModule - End"
    }
}