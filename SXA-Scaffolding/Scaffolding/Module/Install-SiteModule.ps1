function Install-SiteModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$siteSetup,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$sites
    )

    begin {
        Write-Verbose "Cmdlet Install-SiteModule - Begin"
        Import-Function Test-CanInstallModuleSoft
        Import-Function Test-CanInstallSiteModuleHard
        Import-Function Add-SiteModule
        Import-Function Show-SiteSelectionDialog
        Import-Function Get-ItemWithoutModuleInstalled
        Import-Function Install-DependenciesForSiteModule
    }

    process {
        $sitesWithoutModule = Get-ItemWithoutModuleInstalled $sites $siteSetup
        if ($sitesWithoutModule.Count -eq 0) {
            Show-Alert ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThereAreNoSitesWithoutThisModule))
            Exit
        }        

        $validatedSites = [System.Collections.ArrayList]::new()
        $sitesWithoutModule | ? { Test-CanInstallModuleSoft $_ $siteSetup } | % { $validatedSites.Add($_) } | Out-Null
        $sitesInvalid = [System.Collections.ArrayList]::new()
        Compare-Object $sitesWithoutModule $validatedSites | ? { $_.SideIndicator -eq '<=' } | % { $sitesInvalid.Add($_.InputObject.ID) } | Out-Null

        $dTitle = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddSiteModuleTitle)
        $dDescription = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddSiteModuleDescription) -f $siteSetup.Fields["Name"].Value)
        $validatedSites = Show-SiteSelectionDialog $sitesWithoutModule -DialogTitle $dTitle -DialogDescription $dDescription

        $percentage_start = 0
        $percentage_end = 100
        $percentage_diff = $percentage_end - $percentage_start
        $currentIndex = 0
        $validatedSites | % {
            $site = $_
            $percentComplete = ($percentage_start + 1.0 * $percentage_diff * ($currentIndex++) / ($validatedSites.Count))
            Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddSiteModuleValidation) -f $site.Name) -PercentComplete $percentComplete

            if ($sitesInvalid.Contains($site.ID)) {
                $result = Install-DependenciesForSiteModule $site $siteSetup
                if (!$result) {
                    return # process next site
                }
            }

            $result = Test-CanInstallSiteModuleHard -Site $_ -DefinitionItems $siteSetup
            if ($result) {
                Add-SiteModule $site $siteSetup
            }
            else {
                Write-Host "Could not install module for '$($site.Name)' site because there are missing actions."
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Install-SiteModule - End"
    }
}