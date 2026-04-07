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
        Write-Host "Cmdlet Set-SiteDefinitionName - Begin"
        Import-Function Get-SettingsItem
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Host "Cmdlet Set-SiteDefinitionName - Process"
        Write-Host "  - Site: $($Site.Paths.Path)"
        Write-Host "  - Site definitions mapping: $($SiteDefinitionsMapping.Count) mapping(s)"
        
        if ($siteDefinitionNames -eq $null -or $siteDefinitionNames.Count -eq 0){
            Write-Host "  - Getting site definition names from settings..."
            $settingsItem = Get-SettingsItem $Site
            $sitegroupingItemTemplateId = "{9534A0CC-1055-4A4B-B624-05F2BE277211}"
            $siteItemTemplateId = "{2BB25752-B3BC-4F13-B9CB-38B906D21A33}"
            $sitesGroupingItem = $settingsItem.Children | Select-InheritingFrom $sitegroupingItemTemplateId | Select-Object -First 1
            $siteDefinitionNames = Get-ChildItem -Path $sitesGroupingItem.Paths.Path -Recurse | Select-InheritingFrom $siteItemTemplateId
            Write-Host "  - Found $($siteDefinitionNames.Count) site definition(s)"
        }
        
        $renamedCount = 0
        $siteDefinitionNames | ForEach-Object {
            $currentSite = $_
            $oldSiteDefinitionName = $currentSite.Name
            $newSiteDefinitionName = $SiteDefinitionsMapping[$oldSiteDefinitionName]
            Write-Host "  - Processing site definition: $oldSiteDefinitionName"
            if ($newSiteDefinitionName) {
                Write-Host "    - Renaming from: '$oldSiteDefinitionName' to: '$newSiteDefinitionName'"
                $currentSite.SiteName = $newSiteDefinitionName
                Rename-Item $currentSite.Paths.Path $newSiteDefinitionName
                $renamedCount++
                Write-Host "    - Renamed successfully" -ForegroundColor Green
            }
            else {
                Write-Host "    - Warning: No mapping found for '$oldSiteDefinitionName', skipping rename" -ForegroundColor Yellow
            }
        }
        Write-Host "  - Renamed $renamedCount site definition(s)" -ForegroundColor Green
    }

    end {
        Write-Host "Cmdlet Set-SiteDefinitionName - End"
    }
}