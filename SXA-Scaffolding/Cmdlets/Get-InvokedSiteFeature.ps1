function Get-InvokedSiteFeature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site
    )

    begin {
        Write-Verbose "Cmdlet Get-InvokedSiteFeature - Begin"
        Import-Function Get-GridDefinition
        Import-Function Get-TenantItem
        Import-Function Get-InvokedSiteAction
        Import-Function Get-TenantTemplate
    }

    process {
        Write-Verbose "Cmdlet Get-InvokedSiteFeature - Process"
        $tenant = Get-TenantItem $Site        
        $tenantTemplateRoot = $tenant.Database.GetItem($tenant.Templates) | Wrap-Item
        $tenantTemplates = Get-TenantTemplate $tenantTemplateRoot        
        $features = Get-InvokedSiteAction $tenantTemplates $Site | % {
            $parent = $_
            while ($parent.Parent -ne $null -and $parent.TemplateName -ne "SiteSetupRoot") {
                $parent = $parent.Parent
            }
            $parent
        }

        $deviceItem = Get-Item -Path "/sitecore/layout/Devices/Default"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $gridCoontext = $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Grid.IGridContext])
        $gridDefitinionItem = $gridCoontext.GetGridDefinitionItem($Site, $deviceItem)
        $gridDefinition = Get-GridDefinition "*" | ? { $_."Grid Definition" -eq $gridDefitinionItem.ID}
        $features += $gridDefinition
        $unique = @{}
        $features | ? { $unique[$_.ID] -eq $null } | % { 
            $unique[$_.ID] = $_
            $_
        }
    }
    end {
        Write-Verbose "Cmdlet Get-InvokedSiteFeature - End"
    }
}