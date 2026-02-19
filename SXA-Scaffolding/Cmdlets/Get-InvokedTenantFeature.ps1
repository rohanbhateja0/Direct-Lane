function Get-InvokedTenantFeature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Tenant
    )

    begin {
        Write-Verbose "Cmdlet Get-InvokedTenantFeature - Begin"
        Import-Function Get-GridDefinition
        Import-Function Get-TenantItem
        Import-Function Get-InvokedTenantAction
        Import-Function Get-TenantTemplate
    }

    process {
        Write-Verbose "Cmdlet Get-InvokedTenantFeature - Process"
        $tenant = Get-TenantItem $Tenant        
        $tenantTemplateRoot = $tenant.Database.GetItem($tenant.Templates) | Wrap-Item
        $tenantTemplates = Get-TenantTemplate $tenantTemplateRoot        
        $features = Get-InvokedTenantAction $tenantTemplates $Tenant | % {
            $parent = $_
            while ($parent.Parent -ne $null -and $parent.TemplateName -ne "TenantSetupRoot") {
                $parent = $parent.Parent
            }
            $parent
        }
        $unique = @{}
        $features | ? { $unique[$_.ID] -eq $null } | % { 
            $unique[$_.ID] = $_
            $_
        }
    }
    end {
        Write-Verbose "Cmdlet Get-InvokedTenantFeature - End"
    }
}