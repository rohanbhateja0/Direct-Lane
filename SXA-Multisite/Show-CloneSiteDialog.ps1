function Show-CloneSiteDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SourceSite
    )

    begin {
        Write-Host "Cmdlet Show-CloneSiteDialog - Begin"
        Write-Host "Importing required functions..."
        Import-Function Get-SettingsItem
        Write-Host "  - Get-SettingsItem imported"
        Import-Function Get-ForbiddenSiteName
        Write-Host "  - Get-ForbiddenSiteName imported"
        Import-Function Get-SiteDefinitionDialogKey
        Write-Host "  - Get-SiteDefinitionDialogKey imported"
        Import-Function Get-UniqueName
        Write-Host "  - Get-UniqueName imported"
        Import-Function Get-TenantItem
        Write-Host "  - Get-TenantItem imported"
        Import-Function Select-InheritingFrom
        Write-Host "  - Select-InheritingFrom imported"
        Write-Host "All functions imported successfully"
    }

    process {
        Write-Host "Cmdlet Show-CloneSiteDialog - Process"
        Write-Host "Source Site: $($SourceSite.Paths.Path)"
        
        Write-Host "Getting forbidden site names..."
        $forbiddenSiteNames = Get-ForbiddenSiteName $SourceSite.Parent
        Write-Host "  - Found $($forbiddenSiteNames.Count) forbidden site names"

        Write-Host "Generating unique site name..."
        $siteName = Get-UniqueName ($SourceSite.Name + " clone") $forbiddenSiteNames
        Write-Host "  - Generated site name: $siteName"
        
        Write-Host "Getting tenant item..."
        $Root = Get-TenantItem $SourceSite
        Write-Host "  - Tenant root: $($Root.Paths.Path)"
        
        Write-Host "Creating dialog parameters..."
        $dialogParameters = New-Object System.Collections.ArrayList
        $dialogParameters.Add(@{ Name = "siteName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::SiteName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::CloneSiteDialogGeneralTab) })  > $null
        Write-Host "  - Added siteName parameter"
        $dialogParameters.Add(@{ Name = "siteLocation"; Value = $Root; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::SiteLocation)); Root = $Root.Paths.Path; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::CloneSiteDialogGeneralTab)) })  > $null
        Write-Host "  - Added siteLocation parameter"
        
        Write-Host "Getting settings item..."
        $settingsItem = Get-SettingsItem $SourceSite
        Write-Host "  - Settings item: $($settingsItem.Paths.Path)"
        
        $sitegroupingItemTemplateId = "{9534A0CC-1055-4A4B-B624-05F2BE277211}"
        $siteItemTemplateId = "{2BB25752-B3BC-4F13-B9CB-38B906D21A33}"
        Write-Host "  - Site grouping template ID: $sitegroupingItemTemplateId"
        Write-Host "  - Site item template ID: $siteItemTemplateId"
        
        Write-Host "Finding sites grouping item..."
        $sitesGroupingItem = $settingsItem.Children | Select-InheritingFrom $sitegroupingItemTemplateId | Select-Object -First 1
        Write-Host "  - Sites grouping item: $($sitesGroupingItem.Paths.Path)"
        
        Write-Host "Getting site definition names..."
        $siteDefinitionNames = Get-ChildItem -Path $sitesGroupingItem.Paths.Path -Recurse | Select-InheritingFrom $siteItemTemplateId | % { $_.Name }
        Write-Host "  - Found $($siteDefinitionNames.Count) site definition(s): $($siteDefinitionNames -join ', ')"
        

        Write-Host "Creating site definition keys and dialog parameters..."
        $siteDefinitionKeys = New-Object -TypeName "System.Collections.Hashtable"
        $siteDefinitionNames | % {
            Write-Host "  - Processing site definition: $_"
            $siteDefinitionKey = Get-SiteDefinitionDialogKey $_            
            $siteDefinitionKeys.Add($_, $siteDefinitionKey)
            Write-Host "    - Dialog key: $siteDefinitionKey"
            $siteDefinitionDefaultValue = Get-UniqueName "$($_)_clone" $forbiddenSiteNames
            Write-Host "    - Default value: $siteDefinitionDefaultValue"
            
            $dialogParameters.Add(@{ Name = $siteDefinitionKey; Title = "'$_' site definition"; Value = $siteDefinitionDefaultValue; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::CloneSiteDialogDefinitionsTab) }) > $null
        }
        Write-Host "  - Total dialog parameters: $($dialogParameters.Count)"
        
        Write-Host "Displaying clone site dialog..."
        $result = Read-Variable -Parameters `
            $dialogParameters `
            -Description $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ThisScriptCloneAnExistingSite)) `
            -Title $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::CloneSite)) -Width 500 -Height 600 `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("OK")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `
            -Validator {
            Write-Host "  - Validating dialog input..."
            $siteName = $variables.siteName.Value;
            Write-Host "    - Validating site name: $siteName"
            $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
            if ($siteName.Length -gt 100) {
                Write-Host "      - Error: Site name length exceeds 100 characters"
                $variables.siteName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                continue
            }
            if ([System.Text.RegularExpressions.Regex]::IsMatch($siteName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                Write-Host "      - Error: Site name does not match valid pattern"
                $variables.siteName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::IsNotAValidName)) -f $siteName
                continue
            }
            Write-Host "      - Site name validation passed"
            
            $siteLocation = $variables.siteLocation.Value;
            Write-Host "    - Validating site location: $($siteLocation.Paths.Path)"
            $normalized = $siteName.TrimEnd()
            $itemsWithTheSameName = $siteLocation.Children | ? { $_.Name -eq $normalized }
            if ($itemsWithTheSameName.Count -gt 0) {
                Write-Host "      - Error: Item with same name already exists at location"
                $variables.siteName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::THE_ITEM_NAME_0_IS_ALREADY_DEFINED_ON_THIS_LEVEL)) -f $siteName
                continue
            }
            
            Write-Host "    - Checking template inheritance..."
            $rootTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($siteLocation)
            
            $inheritsFromTenant = $rootTemplate.InheritsFrom([Sitecore.XA.Foundation.Multisite.Templates+_BaseTenant]::ID)
            $inheritsFromSiteFolder = $rootTemplate.InheritsFrom([Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteFolder]::ID)
            Write-Host "      - Inherits from Tenant: $inheritsFromTenant"
            Write-Host "      - Inherits from Site Folder: $inheritsFromSiteFolder"
            if (!$inheritsFromTenant -and !$inheritsFromSiteFolder) {
                Write-Host "      - Error: Invalid location template"
                $variables.siteLocation.Error = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::InvalidLocation)
            }

            Write-Host "    - Validating site definition names..."
            $siteDefinitionNames | % {
                $key = $siteDefinitionKeys[$_]
                $sdName = $variables."$key".Value;
                Write-Host "      - Validating site definition '$key': $sdName"
                $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
                if ($sdName.Length -gt 100) {
                    Write-Host "        - Error: Name length exceeds 100 characters"
                    $variables."$key".Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                    continue
                }
                if ($forbiddenSiteNames -contains $sdName -eq $true) {
                    Write-Host "        - Error: Name is in forbidden list"
                    $variables."$key".Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteWithThatNameAlreadyExists))
                    continue
                }
                if ([System.Text.RegularExpressions.Regex]::IsMatch($sdName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                    Write-Host "        - Error: Name does not match valid pattern"
                    $variables."$key".Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $sdName
                    continue
                }
                Write-Host "        - Validation passed"
            }
            Write-Host "  - All validations completed"
        } `
            -ValidatorParameters @{
            forbiddenSiteNames  = $forbiddenSiteNames
            siteDefinitionNames = $siteDefinitionNames
            siteDefinitionKeys  = $siteDefinitionKeys
        }

        Write-Host "Dialog result: $result"
        if ($result -ne "ok") {
            Write-Host "  - Dialog cancelled or closed, exiting..."
            Close-Window
            Exit
        }
        Write-Host "  - Dialog confirmed, proceeding..."
        
        
        Write-Host "Creating site definition mapping..."
        $mapping = New-Object -TypeName "System.Collections.Hashtable"
        $siteDefinitionNames | ForEach-Object {
            $siteDefinitionName = $_            
            $key = Get-SiteDefinitionDialogKey $siteDefinitionName
            $value = $(Get-Variable $key -ErrorAction SilentlyContinue).Value
            Write-Host "  - Mapping '$siteDefinitionName' -> '$value'"
            $mapping.Add($siteDefinitionName, $value)
        }
        Write-Host "  - Created $($mapping.Count) mapping(s)"
        
        Write-Host "Preparing return object..."
        Write-Host "  - Site Name: $siteName"
        Write-Host "  - Site Location: $($siteLocation.Paths.Path)"
        Write-Host "  - Site Definition Mappings: $($mapping.Count)"
        
        @{
            siteName              = $siteName
            siteDefinitionmapping = $mapping
            siteLocation          = $siteLocation
        }
    }

    end {
        Write-Host "Cmdlet Show-CloneSiteDialog - End"
    }
}