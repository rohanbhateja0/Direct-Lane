function Get-MissingSiteSetupDependency {
    [CmdletBinding()]
    param(
        [Item]$SiteSetup,
        [Item[]]$InvokedActions
    )
    
    begin {
        Write-Verbose "Cmdlet Get-MissingSiteSetupDependency - Begin"
        Import-Function Test-ItemIsSiteSetup
        Import-Function Select-SingleItemFromEachGroup
    }
    
    process {
        Write-Verbose "Cmdlet Get-MissingSiteSetupDependency - Process"   
        [Sitecore.Data.ID[]]$dependencies = $SiteSetup.Dependencies.Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) }

        Compare-Object $InvokedActions.ID $dependencies | `
            ? { $_.SideIndicator -eq '=>' }  | `
            % { Get-ItemByIdSafe $_.InputObject } | `
            % { [Sitecore.XA.Foundation.SitecoreExtensions.Extensions.ItemExtensions]::GetParentOfTemplate($_, [Sitecore.XA.Foundation.Scaffolding.Templates+_Name]::ID) } | `
            Group-Object ID | Select-SingleItemFromEachGroup | Wrap-Item | % {
            $_
            if (Test-ItemIsSiteSetup $_) {
                Get-MissingSiteSetupDependency $_ $InvokedActions
            }
        }
    } 
    
    end {
        Write-Verbose "Cmdlet Get-MissingSiteSetupDependency - End"
    }
}