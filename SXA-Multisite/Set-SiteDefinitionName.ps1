function Set-SiteDefinitionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1 )]
        [System.Collections.Hashtable]$SiteDefinitionsMapping,

        [Parameter(Mandatory = $false, Position = 2 )]
        [Item[]]$siteDefinitionNames
    )

    begin {
        Write-Verbose "Cmdlet Set-SiteDefinitionName - Begin"
        Import-Function Get-SettingsItem
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Set-SiteDefinitionName - Process"
        if ($siteDefinitionNames -eq $null -or $siteDefinitionNames.Count -eq 0){
            $settingsItem = Get-SettingsItem $Site
            $sitegroupingItemTemplateId = "{9534A0CC-1055-4A4B-B624-05F2BE277211}"
            $siteItemTemplateId = "{2BB25752-B3BC-4F13-B9CB-38B906D21A33}"
            $sitesGroupingItem = $settingsItem.Children | Select-InheritingFrom $sitegroupingItemTemplateId | Select-Object -First 1
            $siteDefinitionNames = Get-ChildItem -Path $sitesGroupingItem.Paths.Path -Recurse | Select-InheritingFrom $siteItemTemplateId
        }
        $siteDefinitionNames | % {
            $currentSite = $_
            $oldSiteDefinitionName = $currentSite.Name
            $newSiteDefinitionName = $SiteDefinitionsMapping[$oldSiteDefinitionName]
            Write-Verbose "Processing $($currentSite.Name) site"
            Write-Verbose "Changing name from: '$oldSiteDefinitionName' to: '$newSiteDefinitionName'"
            if ($newSiteDefinitionName) {
                $currentSite.SiteName = $newSiteDefinitionName
                Rename-Item $currentSite.Paths.Path $newSiteDefinitionName
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Set-SiteDefinitionName - End"
    }
}