Import-Function Get-SiteMediaItem
Import-Function Get-SettingsItem
Import-Function Get-TenantItem
Import-Function Get-PartialDesignsItem
Import-Function Get-PageDesignsItem
Import-Function Test-ItemIsSiteDefinition
Import-Function Get-OrderedDictionaryByKey
Import-Function Set-TenantTemplate
Import-Function Get-TenantTemplate
Import-Function Get-TenantTemplatesRoot
Import-Function Get-SiteDefinitions
Import-Function Get-SortedSetupItemsCollection
Import-Function New-SiteTheme
Import-Function Get-TenantDefinition
Import-Function Get-TenantThemesFolder
Import-Function Get-TenantMediaLibraryRoot
Import-Function Add-FolderStructure
Import-Function Get-ItemOrCreate
Import-Function Get-Action
Import-Function Get-InvokedTenantAction
Import-Function Run-SiteManager
Import-Function Invoke-InputValidationStep
Import-Function Invoke-PostSetupStep
Import-Function Get-GridDefinition


function Show-NewSiteDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteLocation
    )

    begin {
        Write-Host "Cmdlet Show-NewSiteDialog - Begin"
        Import-Function Get-ForbiddenSiteName
        Import-Function Get-ValidSiteSetupDefinition
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::BuildingNewSiteDialog)) -PercentComplete 0
    }

    process {
        Write-Host "Cmdlet Show-NewSiteDialog - Process"
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingTenantTemplates)) -PercentComplete 20
        $tenantTemplatesRoot = Get-TenantTemplatesRoot $SiteLocation
        if ($tenantTemplatesRoot -eq $null) {
            Write-Host "Site Collection Templates root could not be found for a given location: '$($SiteLocation.Paths.Path)'" -ForegroundColor Red
            return
        }
        $TenantTemplates = Get-TenantTemplate $tenantTemplatesRoot

        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary

        [Item[]]$allDefinitions = Get-SiteDefinitions "*"

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingValidSiteDefinitions)) -PercentComplete 30
        $allDefinitions = Get-ValidSiteSetupDefinition $SiteLocation $allDefinitions

        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingDialogOptions)) -PercentComplete 50
        $nonSystemDefinitions = $allDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IsSystemModule']).Checked -eq $false } | ? { $_.IncludeIfInstalled.Length -eq 0 }

        $nonSystemDefinitions | % {
            $contextItem = Get-Item -Path master: -ID $_.ID
            $key = "$($_.Fields['Name'].Value)"
            $translatedFeatureName = $contextItem.Fields['Name'].Value
            if ([string]::IsNullOrEmpty($translatedFeatureName)) {
                $translatedFeatureName = $key
            }
            if ($dialogOptions.Contains($translatedFeatureName)) {
                $index = 2
                do {
                    $translatedFeatureName = $translatedFeatureName + " [$index]"
                    $index++
                } while ($dialogOptions.Contains($translatedFeatureName))
            }

            $dialogOptions.Add($translatedFeatureName, $_.ID)
        }

        $preSelectedDefinitions = $nonSystemDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IncludeByDefault']).Checked -eq $true } | % { $_.ID }

        $languages = [ordered]@{}
        Get-ChildItem -Path "/sitecore/system/languages" | % { $languages[$_.Name] = $_.Name } > $null
        $gridSetupItems = [ordered]@{}
        Get-GridDefinition "*" | ForEach-Object {
            $displayName = $_.Fields['Name'].Value
            if ($displayName -and $displayName.length -gt 0) {
                $gridSetupItems[$displayName] = $_.ID
            }
            else {
                $gridSetupItems[$_.Name] = $_.ID
            }
        }

        $dialogOptions = Get-OrderedDictionaryByKey $dialogOptions
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::OpeningNewSiteDialog)) -PercentComplete 100

        $siteName = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewSite)
        $hostName = "*"
        $virtualFolder = "/"
        $language = "en"
        $createNewTheme = $false
        $cloneExistingSite = $false
        $existingSite = Get-Item -Path master: -ID "{41B32439-45F1-474A-8A75-048A6573F7CE}"

        #Bootstrap Grid Setup ID 4
        $gridSetupID = '{361E981F-8399-47F9-B5F1-2C27BA7BAC09}'
        $themeName = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteThemeName)

        # Existing Sites
        $existingSites = [ordered]@{}
        Get-ChildItem -Path "/sitecore/content/CBRE/Brands" | Where-Object { $_.TemplateName -eq "Site" } | ForEach-Object {
            $existingSites[$_.Name] = $_.ID
        }

        $existingSites = Get-OrderedDictionaryByKey $existingSites
        Write-Host "Existing Sites: $($existingSites.Count)"

        # Parameters
        $parameters = @()
        $parameters += @{ Name = "siteName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }
        $parameters += @{ Name = "hostName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::HostName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }
        $parameters += @{ Name = "virtualFolder"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::VirtualFolder); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }
        $parameters += @{ Name = "language"; Options = $languages; Title = [Sitecore.Globalization.Translate]::Text("Language"); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }
        if ($dialogOptions.Count -gt 0) {
            $parameters += @{ Name = "preSelectedDefinitions"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); Options = $dialogOptions; Editor = "checklist"; Tip = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectTheFeaturesWhichShouldBeUsedInSite); Height = "330px"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); }
        }
        $parameters += @{ Name = "cloneExistingSite"; Title = "CLONE EXISTING SITE"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }
        $parameters += @{ Name = "createNewTheme"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreateNewTheme); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Theme) }
        $parameters += @{ Name = "themeName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewThemeName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Theme) }
        $parameters += @{ Name = "validThemes"; Source = "DataSource=/sitecore/media library/Themes&DatabaseName=master&IncludeTemplatesForSelection=Theme"; editor = "treelist"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThemesUsableByThisSite); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Theme) }
        $parameters += @{ Name = "gridSetupID"; Options = $gridSetupItems; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Grid); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Grid); }
        $parameters += @{ Name = "existingSite"; Options = $existingSites; Title = "EXISTING SITE"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }

        do {
            $result = Read-Variable -Parameters $parameters `
                -Description $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThisScriptWillCreateANewFullyFunctionalSiteWithinYourSxaEnabledInstance)) `
                -Title $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreateANewExperienceAcceleratorSite)) -Width 500 -Height 600 `
                -OkButtonName $([Sitecore.Globalization.Translate]::Text("Ok")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `
                -Validator {
                $siteName = $variables.siteName.Value;
                $themeName = $variables.themeName.Value;
                $createNewTheme = $variables.createNewTheme.Value;
                $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
                if ($siteName.Length -gt 100) {
                    $variables.siteName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                    continue
                }
                if ([System.Text.RegularExpressions.Regex]::IsMatch($siteName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                    $variables.siteName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $siteName
                    continue
                }
                if ($forbiddenSiteNames -contains $siteName -eq $true) {
                    $variables.siteName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteWithThatNameAlreadyExists))
                    continue
                }
                if ($createNewTheme) {
                    if ($themeName.Length -gt 100) {
                        $variables.themeName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                        continue
                    }
                    if ([System.Text.RegularExpressions.Regex]::IsMatch($themeName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                        $variables.themeName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $themeName
                        continue
                    }
                }
            } `
                -ValidatorParameters @{forbiddenSiteNames = (Get-ForbiddenSiteName $SiteLocation) }

            if ($result -ne "ok") {
                Close-Window
                Exit
            }

            $definitionItems = New-Object System.Collections.ArrayList($null)
            if ($preSelectedDefinitions ) {
                Write-Host "Adding pre-selected features"
                [Item[]]$preSelectedDefinitionItems = ($preSelectedDefinitions | % { Get-Item -Path master: -ID $_ })
                $definitionItems.AddRange($preSelectedDefinitionItems)
            }

            [Item[]]$systemFeatures = $allDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IsSystemModule']).Checked -eq $true }
            if ($systemFeatures) {
                Write-Host "Adding system features"
                $definitionItems.AddRange($systemFeatures)
            }

            $invokedTenantActions = Get-InvokedTenantAction $TenantTemplates $SiteLocation
            [Item[]]$autoIncludedFeatures = $allDefinitions | ? { $_.IncludeIfInstalled.Length -gt 0 } | ? {
                $_.IncludeIfInstalled.Split("|") | ? {
                    $tenantActionID = $_
                    $invokedTenantActions | ? { $_.ID -eq $tenantActionID }
                }
            }
            if ($autoIncludedFeatures) {
                Write-Host "Adding auto-included features"
                $definitionItems.AddRange($autoIncludedFeatures)
            }


            $gridSetupItem = Get-Item -Path master: -ID $gridSetupID
            if ($gridSetupItem) {
                Write-Host "Adding grid feature"
                $definitionItems.Add($gridSetupItem) > $null
            }
            $model = New-Object CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel
            $model.SiteName = $siteName.TrimEnd(" ")
            $model.DefinitionItems = $definitionItems
            $model.CreateSiteTheme = $createNewTheme
            $model.ThemeName = $themeName
            $model.ValidThemes = $validThemes
            $model.Language = $language
            $model.HostName = $hostName
            $model.VirtualFolder = $virtualFolder
            $model.GridSetup = $gridSetupItem
            $model.SiteLocation = $SiteLocation
            $model.CloneExistingSite = $cloneExistingSite
            $model.ExistingSite = $existingSite
            # $inputValidationResult = Invoke-PreSiteCreationValidation $model
            $inputValidationResult = $true
        } while (-not($inputValidationResult))
        $model
    }

    end {
        Write-Host "Cmdlet Show-NewSiteDialog - End"
    }
}

function New-Site {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model
    )

    begin {
        Write-Host "Cmdlet New-Site - Begin"
        Import-Function Invoke-SiteAction
        Import-Function New-MappingString
        Import-Function Add-SiteMediaLibrary
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Host "Cmdlet New-Site - Process"
        New-UsingBlock (New-Object Sitecore.Data.BulkUpdateContext) {
            if ($Model.SiteName -and $Model.DefinitionItems) {
                New-UsingBlock ([Sitecore.Configuration.SettingsSwitcher]::new("Sitecore.ThumbnailsGeneration.Enabled", $false)) {
                    [string]$SiteName = $Model.SiteName
                    [Item[]]$DefinitionItems = Get-SortedSetupItemsCollection $Model.DefinitionItems
                    [string]$language = $Model.Language
                    [string]$hostName = $Model.HostName
                    [string]$virtualFolder = $Model.VirtualFolder
                    [Item]$gridSetupItem = $Model.GridSetup
                    [Item]$SiteLocation = $Model.SiteLocation

                    $CreateSiteTheme = $Model.CreateSiteTheme
                    $ThemeName = $Model.ThemeName
                    [Item[]]$ValidThemes = $Model.ValidThemes

                    Write-Host "Cmdlet Add-Site - Process"
                    Write-Host "Creating site ($SiteName) under: $($SiteLocation.Paths.Path)"
                    Write-Host "Definitions items count: $($DefinitionItems.Length)"
                    $siteBranch = "Branches/Foundation/Experience Accelerator/Scaffolding/Site"

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingTenantItem)) -PercentComplete 0
                    $tenant = Get-TenantItem $SiteLocation
                    $tenantTemplatesRootID = $tenant.Fields['Templates'].Value
                    $tenantTemplatesRoot = Get-Item -Path master: -ID $tenantTemplatesRootID

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingTenantTemplates)) -PercentComplete 10
                    $tenantTemplates = Get-TenantTemplate $tenantTemplatesRoot
                    $site = New-Item -Parent $SiteLocation -Name $SiteName -ItemType $siteBranch -Language $language

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SettingTenantTemplatesLocation)) -PercentComplete 15
                    Set-TenantTemplate $site $tenantTemplates

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingSiteMediaLibrary)) -PercentComplete 20
                    $siteMediaLibrary = Add-SiteMediaLibrary $site
                    $settingsItem = Get-SettingsItem $Site
                    $settingsItem.MediaLibrary = $siteMediaLibrary.ID
                    $settingsItem.Templates = $tenant.Templates
                    (Get-SiteMediaItem $Site).AdditionalChildren = $siteMediaLibrary.ID, $tenant.SharedMediaLibrary -join "|"

                    $siteThemesFolder = Get-SiteThemesFolder $site
                    $siteTheme = $null
                    if ($CreateSiteTheme) {
                        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingSiteTheme)) -PercentComplete 25
                        $themeModel = New-Object Sitecore.XA.Foundation.Scaffolding.Models.CreateNewSiteThemeModel
                        $themeModel.ThemeName = $ThemeName
                        $themeModel.SiteLocation = $site
                        $themeModel.ThemeLocation = $siteThemesFolder
                        $themeModel.Language = $language
                        $themeModel.DefinitionItems = $DefinitionItems
                        $siteTheme = New-SiteTheme $themeModel
                    }

                    $site.SiteMediaLibrary = $siteMediaLibrary.ID
                    $site.ThemesFolder = $siteThemesFolder.ID

                    # Editing Theme
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingEditingTheme)) -PercentComplete 34
                    $baseEditingThemeID = "{BB9FCC9B-9302-41B4-B75E-849A1870E6ED}"
                    $editingTheme = New-EditingTheme $siteThemesFolder "Editing Theme" $baseEditingThemeID $language
                    $settingsItem.EditingTheme = $editingTheme.ID


                    $percentage_start = 35
                    $percentage_end = 85
                    $percentage_diff = $percentage_end - $percentage_start
                    $Items = Get-ChildItem -Path $site.Paths.Path -Recurse
                    foreach ($definitionItem in $DefinitionItems) {
                        $currentIndex = $DefinitionItems.IndexOf($definitionItem)
                        $percentComplete = ($percentage_start + 1.0 * $percentage_diff * ($currentIndex) / ($DefinitionItems.Count))
                        $currentOperation = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InstallingFeature)) -f $definitionItem._Name
                        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ($currentOperation) -PercentComplete $percentComplete
                        $actions = $definitionItem | Get-Action
                        foreach ($actionItem in $actions) {
                            Invoke-SiteAction $site $actionItem -EditingTheme $editingTheme -language $language
                        }
                    }

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SettingDefaultValues)) -PercentComplete 90
                
                    $defaultDeviceID = "{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}"
                    if ($ValidThemes) {
                        $selectedValidThemes = ($ValidThemes | % { $_.ID }) -join "|"
                        $settingsItem.Themes = $settingsItem.Themes, $selectedValidThemes -join "|"
                        $defaultThemeID = $ValidThemes | % { $_.ID } | Select-Object -First 1
                    (Get-PageDesignsItem $Site).Theme = New-MappingString @{"$defaultDeviceID" = "$defaultThemeID"; }
                    }
                    $settingsItem.'Grid Mapping' = New-MappingString @{"$defaultDeviceID" = $gridSetupItem.'Grid Definition'; }

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ConfiguringSiteDefinitionItem)) -PercentComplete 93
                    $siteDefinitionItem = Get-ChildItem -Recurse -Path ($settingsItem.Paths.Path) | ? { (Test-ItemIsSiteDefinition $_) -eq $true } | Select-Object -First 1
            
                    $siteDefinitionItem.HostName = $hostName
                    $siteDefinitionItem.VirtualFolder = $virtualFolder
                    $siteDefinitionItem.Editing.BeginEdit()
                    $siteDefinitionItem.Fields["Language"].Value = $language
                    $siteDefinitionItem.Editing.EndEdit() >> $null

                    if ([string]::IsNullOrWhiteSpace($siteDefinitionItem.SiteName) -or ("`$name" -eq $siteDefinitionItem.SiteName)) {
                        $siteDefinitionItem.SiteName = $siteDefinitionItem.Name
                    }
            
                    if ([string]::IsNullOrWhiteSpace($siteDefinitionItem.Environment)) {
                        $siteDefinitionItem.Environment = "*"
                    }
            
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InitializingPresentation)) -PercentComplete 95
                    Initialize-Presentation $site $tenantTemplates $language

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SettingTenantTemplatesLocation)) -PercentComplete 99
                    Set-TenantTemplate $site $tenantTemplates
            
                    $site = $site.Database.GetItem($site.ID, $site.Language) | Wrap-Item
                    $site.Modules = $DefinitionItems.ID -join "|"            

                    # Set Page Not Found Link to 404 page under home/404
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Setting Page Not Found Link" -PercentComplete 98
                    Set-PageNotFoundLink -Site $site -SettingsItem $settingsItem -Language $language

                    # Set additional site settings fields
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Setting Site Settings Fields" -PercentComplete 99
                    Set-SiteSettingsFields -SettingsItem $settingsItem

                    # Rename HTML Snippets and clear Privacy Warning Type field
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Updating Settings Items" -PercentComplete 99
                    Update-SettingsItems -SettingsItem $settingsItem -Language $language

                    # Update Site Grouping item
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Updating Site Grouping" -PercentComplete 99
                    Update-SiteGrouping -Site $site -SettingsItem $settingsItem -SiteDefinitionItem $siteDefinitionItem -Language $language

                    # Update Dictionary item
                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Updating Dictionary Item" -PercentComplete 99
                    $siteNameForDict = $site.Name
                    if ($siteDefinitionItem.SiteName -and $siteDefinitionItem.SiteName -ne "*" -and $siteDefinitionItem.SiteName -ne "`$name") {
                        $siteNameForDict = $siteDefinitionItem.SiteName
                    }
                    Update-DictionaryItem -Site $site -SiteName $siteNameForDict

                    Invoke-PostSiteSetupStep $Model
                    Run-SiteManager
                } >> $null

                if ([Sitecore.Configuration.Settings]::GetSetting('Sitecore.ThumbnailsGeneration.Enabled') -eq "true") {
                    $path = Join-Path $Model.SiteLocation.Paths.Path $Model.SiteName
                    $homeItem = Get-ChildItem -Path $path -Language $Model.Language | Select-InheritingFrom ([Sitecore.XA.Foundation.Multisite.Templates+Page]::ID.ToString()) | Select-Object -First 1
                    if ($homeItem) {
                        $homeItem.__Revision = [System.Guid]::NewGuid()
                        Get-ChildItem -Path $homeItem.Paths.Path -Language $Model.Language -Recurse | Select-InheritingFrom ([Sitecore.XA.Foundation.Multisite.Templates+Page]::ID.ToString()) | % {
                            $_.__Revision = [System.Guid]::NewGuid()
                        }                        
                    }
                }
            }
            else {
                Write-Error "Could not create site. Site name or module definitions is undefined"
            }
        }
    }
    end {
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::YourSiteHasBeenCreated)) -CurrentOperation "" -PercentComplete 100
        Write-Host "Cmdlet New-Site - End"
    }
}

function Invoke-PostSiteSetupStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model
    )

    begin {
        Write-Host "Cmdlet Invoke-PostSiteSetupStep - Begin"
    }

    process {
        Write-Host "Cmdlet Invoke-PostSiteSetupStep - Process"
        Invoke-PostSetupStep $Model.DefinitionItems $Model
    }

    end {
        Write-Host "Cmdlet Invoke-PostSiteSetupStep - End"
    }
}

function Invoke-PreSiteCreationValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model
    )

    begin {
        Write-Host "Cmdlet Invoke-PreSiteCreationValidation - Begin"
    }

    process {
        Write-Host "Cmdlet Invoke-PreSiteCreationValidation - Process"
        Invoke-InputValidationStep $Model.DefinitionItems $Model
    }

    end {
        Write-Host "Cmdlet Invoke-PreSiteCreationValidation - End"
    }
}

function Initialize-Presentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteItem,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$TenantTemplates,

        [Parameter(Mandatory = $false, Position = 2 )]
        [string]$Language = "en"
    )

    begin {
        Write-Host "Cmdlet Initialize-Presentation - Begin"
    }

    process {
        Write-Host "Cmdlet Initialize-Presentation - Process"
        $pageDesigns = Get-PageDesignsItem $SiteItem
        $partialDesigns = Get-PartialDesignsItem $SiteItem
        $designTemplate = Get-Item master: -ID ([Sitecore.XA.Foundation.Presentation.Templates+Design]::ID)
        $defaultDesign = New-Item -Parent $pageDesigns -Name "Default" -ItemType $designTemplate.Paths.Path -Language $Language | Wrap-Item
        $partialDesignsIDs = $partialDesigns.Children | ? { ($_.Name -eq "Empty") -or ($_.Name -eq "Metadata") } | % { $_.ID }
        $defaultDesign.PartialDesigns = $partialDesignsIDs -join '|'

        $pageTemplates = $TenantTemplates | ? { [Sitecore.XA.Foundation.SitecoreExtensions.Extensions.ItemExtensions]::DoesTemplateInheritFrom($_, '{3F8A6A5D-7B1A-4566-8CD4-0A50F3030BD8}') }
        $mappings = @{}
        $pageTemplates | ForEach-Object { $mappings.Add($_.ID, "$($defaultDesign.ID)") }
        $pageDesigns.TemplatesMapping = New-MappingString $mappings
    }

    end {
        Write-Host "Cmdlet Initialize-Presentation - End"
    }
}

function Get-SiteThemesFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site
    )

    begin {
        Write-Host "Cmdlet Get-SiteThemesFolder - Begin"
    }

    process {
        Write-Host "Cmdlet Get-SiteThemesFolder - Process"
        $TenantThemesFolder = Get-TenantThemesFolder $site

        $folderType = "/System/Media/Media folder"
        $folderName = $Site.Name

        $themesFolder = Get-ItemOrCreate $TenantThemesFolder $folderName $folderType
        return $themesFolder
    }

    end {
        Write-Host "Cmdlet Get-SiteThemesFolder - End"
    }
}

function New-EditingTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ThemeLocation,

        [Parameter(Mandatory = $true, Position = 1 )]
        [string]$ThemeName,

        [Parameter(Mandatory = $false, Position = 2 )]
        [Sitecore.Data.ID[]]$BaseThemesID,

        [Parameter(Mandatory = $false, Position = 3 )]
        [string]$Language = "en"
    )

    begin {
        Write-Host "Cmdlet New-EditingTheme - Begin"
    }

    process {
        Write-Host "Cmdlet New-EditingTheme - Process"
        $baseTheme = Get-Item master: -ID ([Sitecore.XA.Foundation.Theming.Templates+BaseTheme]::ID)
        $siteTheme = New-Item -Parent $ThemeLocation -ItemType $baseTheme.Paths.Path  -Name $ThemeName  -Language $Language
        if ($BaseThemesID) {
            $siteTheme.BaseLayout = $BaseThemesID -join '|'
        }
        $siteTheme
    }

    end {
        Write-Host "Cmdlet New-EditingTheme - End"
    }
}

function Set-PageNotFoundLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [Item]$SettingsItem,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$Language = "en"
    )

    begin {
        Write-Host "Cmdlet Set-PageNotFoundLink - Begin"
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Host "Cmdlet Set-PageNotFoundLink - Process"
        Write-Host "Starting to set Page Not Found Link (Error404Page) field..."
        Write-Host "Found site: $($Site.Paths.Path) (ID: $($Site.ID))"
        Write-Host "Searching for home item under site path: $($Site.Paths.Path) in language: $Language"
        $homeItem = Get-ChildItem -Path $Site.Paths.Path -Language $Language | Select-InheritingFrom ([Sitecore.XA.Foundation.Multisite.Templates+Page]::ID.ToString()) | Select-Object -First 1
        if ($homeItem) {
            Write-Host "Found home item: $($homeItem.Paths.Path) (ID: $($homeItem.ID))"
            Write-Host "Searching for 404 page under home item path: $($homeItem.Paths.Path)"
            $notFoundPage = Get-ChildItem -Path $homeItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "404" } | Select-Object -First 1
            if ($notFoundPage) {
                Write-Host "Found 404 page: $($notFoundPage.Paths.Path) (ID: $($notFoundPage.ID))"
                Write-Host "Setting Error404Page field on settings item: $($SettingsItem.Paths.Path)"
                $notFoundPagePath = $notFoundPage.Paths.Path
                Write-Host "Setting droplink field value to path: $notFoundPagePath"
                $SettingsItem.Editing.BeginEdit()
                $SettingsItem.Fields["Error404Page"].Value = $notFoundPagePath
                $SettingsItem.Editing.EndEdit() >> $null
                Write-Host "Successfully set Error404Page field to path: $notFoundPagePath" -ForegroundColor Green
            }
            else {
                Write-Warning "404 page not found under home item at: $($homeItem.Paths.Path)"
                Write-Host "Available items under home: $((Get-ChildItem -Path $homeItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
            }
        }
        else {
            Write-Warning "Home item not found for site: $($Site.Paths.Path)"
            Write-Host "Available items under site: $((Get-ChildItem -Path $Site.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
    }

    end {
        Write-Host "Cmdlet Set-PageNotFoundLink - End"
    }
}

function Set-SiteSettingsFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$SettingsItem
    )

    begin {
        Write-Host "Cmdlet Set-SiteSettingsFields - Begin"
    }

    process {
        Write-Host "Cmdlet Set-SiteSettingsFields - Process"
        Write-Host "Setting additional site settings fields on: $($SettingsItem.Paths.Path)"
        
        $SettingsItem.Editing.BeginEdit()
        
        # Set SchemaLocation
        $schemaLocationPath = "/sitecore/content/CBRE/Shared/Shared Content/Data/Schema"
        Write-Host "Setting SchemaLocation field to: $schemaLocationPath"
        if (Test-Path "master:$schemaLocationPath") {
            $SettingsItem.Fields["SchemaLocation"].Value = $schemaLocationPath
            Write-Host "Successfully set SchemaLocation field to: $schemaLocationPath" -ForegroundColor Green
        }
        else {
            Write-Warning "SchemaLocation path not found: $schemaLocationPath"
        }
        
        # Set SharedContentLocation
        $sharedContentLocationPath = "/sitecore/content/CBRE/Shared/Shared Content/Home/Content"
        Write-Host "Setting SharedContentLocation field to: $sharedContentLocationPath"
        if (Test-Path "master:$sharedContentLocationPath") {
            $SettingsItem.Fields["SharedContentLocation"].Value = $sharedContentLocationPath
            Write-Host "Successfully set SharedContentLocation field to: $sharedContentLocationPath" -ForegroundColor Green
        }
        else {
            Write-Warning "SharedContentLocation path not found: $sharedContentLocationPath"
        }
        
        # Set SiteLanguages
        $enLanguageId = "{AF584191-45C9-4201-8740-5409F4CF8BDD}"
        Write-Host "Setting SiteLanguages field to EN Language item ID: $enLanguageId"
        $enLanguageItem = Get-Item -Path master: -ID $enLanguageId -ErrorAction SilentlyContinue
        if ($enLanguageItem) {
            Write-Host "Found EN Language item: $($enLanguageItem.Paths.Path) (ID: $($enLanguageItem.ID))"
            $SettingsItem.Fields["SiteLanguages"].Value = $enLanguageId
            Write-Host "Successfully set SiteLanguages field to: $enLanguageId" -ForegroundColor Green
        }
        else {
            Write-Warning "EN Language item not found with ID: $enLanguageId"
        }
        
        $SettingsItem.Editing.EndEdit() >> $null
        Write-Host "Completed setting site settings fields" -ForegroundColor Green
    }

    end {
        Write-Host "Cmdlet Set-SiteSettingsFields - End"
    }
}

function Update-SettingsItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$SettingsItem,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Language = "en"
    )

    begin {
        Write-Host "Cmdlet Update-SettingsItems - Begin"
    }

    process {
        Write-Host "Cmdlet Update-SettingsItems - Process"
        Write-Host "Updating settings items under: $($SettingsItem.Paths.Path)"
        
        # Rename HTML Snippets to HTML-Snippets
        $htmlSnippetsItem = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "HTML Snippets" } | Select-Object -First 1
        if ($htmlSnippetsItem) {
            Write-Host "Found HTML Snippets item: $($htmlSnippetsItem.Paths.Path) (ID: $($htmlSnippetsItem.ID))"
            Write-Host "Renaming 'HTML Snippets' to 'HTML-Snippets'"
            # $htmlSnippetsItem.Editing.BeginEdit()
            # $htmlSnippetsItem.Name = "HTML-Snippets"
            # $htmlSnippetsItem.Editing.EndEdit() >> $null
            Write-Host "Successfully renamed to: HTML-Snippets" -ForegroundColor Green
        }
        else {
            Write-Warning "HTML Snippets item not found under: $($SettingsItem.Paths.Path)"
            Write-Host "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
        
        # Clear Privacy Warning Type field on Privacy Warning item
        $privacyWarningItem = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "Privacy Warning" } | Select-Object -First 1
        if ($privacyWarningItem) {
            Write-Host "Found Privacy Warning item: $($privacyWarningItem.Paths.Path) (ID: $($privacyWarningItem.ID))"
            Write-Host "Clearing Privacy Warning Type field"
            $privacyWarningItem.Editing.BeginEdit()
            $privacyWarningItem.Fields["PrivacyWarningType"].Value = ""
            $privacyWarningItem.Editing.EndEdit() >> $null
            Write-Host "Successfully cleared Privacy Warning Type field" -ForegroundColor Green
        }
        else {
            Write-Warning "Privacy Warning item not found under: $($SettingsItem.Paths.Path)"
            Write-Host "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
    }

    end {
        Write-Host "Cmdlet Update-SettingsItems - End"
    }
}

function Update-SiteGrouping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [Item]$SettingsItem,

        [Parameter(Mandatory = $true, Position = 2)]
        [Item]$SiteDefinitionItem,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$Language = "en"
    )

    begin {
        Write-Host "Cmdlet Update-SiteGrouping - Begin"
        Import-Function Select-InheritingFrom
        Import-Function Get-DictionaryItem
    }

    process {
        Write-Host "Cmdlet Update-SiteGrouping - Process"
        Write-Host "Updating Site Grouping item under: $($SettingsItem.Paths.Path)"
        
        # Get site name first
        $siteName = $Site.Name
        if ($SiteDefinitionItem.SiteName -and $SiteDefinitionItem.SiteName -ne "*" -and $SiteDefinitionItem.SiteName -ne "`$name") {
            $siteName = $SiteDefinitionItem.SiteName
        }
        
        Write-Host "Site Name: $siteName"
        
        # Find Site Grouping folder first
        [Sitecore.Data.ID]$_baseSiteGrouping = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteGrouping]::ID
        $siteGroupingFolder = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-InheritingFrom $_baseSiteGrouping | Select-Object -First 1
        
        if (-not $siteGroupingFolder) {
            Write-Warning "Site Grouping folder not found under: $($SettingsItem.Paths.Path)"
            Write-Host "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
            return
        }
        
        Write-Host "Found Site Grouping folder: $($siteGroupingFolder.Paths.Path) (ID: $($siteGroupingFolder.ID))"
        
        # Find the site grouping item inside the folder (named after the site)
        $siteGroupingItem = Get-ChildItem -Path $siteGroupingFolder.Paths.Path -Language $Language | Where-Object { $_.Name -eq $siteName } | Select-Object -First 1
        
        if (-not $siteGroupingItem) {
            Write-Warning "Site Grouping item named '$siteName' not found under: $($siteGroupingFolder.Paths.Path)"
            Write-Host "Available items under Site Grouping folder: $((Get-ChildItem -Path $siteGroupingFolder.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
            return
        }
        
        Write-Host "Found Site Grouping item: $($siteGroupingItem.Paths.Path) (ID: $($siteGroupingItem.ID))"
        
        # Get environment name from Sitecore configuration
        $environmentName = [Sitecore.Configuration.Settings]::GetSetting("XA.Foundation.Multisite.Environment")
        if ([string]::IsNullOrWhiteSpace($environmentName)) {
            Write-Warning "InstanceName setting not found, defaulting to PROD"
            $environmentName = "PROD"
        }
        
        Write-Host "Site Name: $siteName"
        Write-Host "Environment (from InstanceName): $environmentName"
        
        # Determine hostname based on environment
        $hostName = ""
        if ($environmentName -eq "PREPROD" -or $environmentName -eq "DEV") {
            $hostName = "uat-preview.cbre.com"
        }
        elseif ($environmentName -eq "PROD") {
            $hostName = "preview.cbre.com"
        }
        else {
            Write-Warning "Unknown environment '$environmentName', defaulting to preview.cbre.com"
            $hostName = "preview.cbre.com"
        }
        
        Write-Host "Target HostName: $hostName"
        
        # Get dictionary item for OtherProperties
        $dictionaryItemId = (Get-DictionaryItem -CurrentItem $Site).ID.ToString()
        
        # Build new name and other properties
        $newName = "$siteName-$environmentName-Preview"
        Write-Host "Renaming Site Grouping item to: $newName"
        
        # Build OtherProperties value
        $otherProperties = "dictionaryDomain=$dictionaryItemId"
        Write-Host "OtherProperties: $otherProperties"
        
        # Update all fields
        Write-Host "Setting fields on Site Grouping item"
        $siteGroupingItem.Editing.BeginEdit()


        # Set VirtualFolder field if empty or "/"
        $virtualFolder = $siteGroupingItem.Fields["VirtualFolder"].Value
        if ([string]::IsNullOrWhiteSpace($virtualFolder) -or $virtualFolder -eq "/") {
            $newVirtualFolder = "/$siteName"
            Write-Host "Setting VirtualFolder field on Site Grouping item from '$virtualFolder' to: $newVirtualFolder"
            $siteGroupingItem.Fields["VirtualFolder"].Value = $newVirtualFolder
            Write-Host "Successfully set VirtualFolder field to: $newVirtualFolder" -ForegroundColor Green
        }
        else {
            Write-Host "VirtualFolder field already has value: $virtualFolder, skipping update"
        }

        # Set NeverPublish field
        if ($siteGroupingItem.Fields["NeverPublish"]) {
            $siteGroupingItem["NeverPublish"].Value = "1"
            Write-Host "Set NeverPublish field to: 1" -ForegroundColor Green
        }
        else {
            Write-Warning "NeverPublish field not found on Site Grouping item"
        }

        # Rename the item
        $siteGroupingItem.Name = $newName
        
        # Set SiteName
        if ($siteGroupingItem.Fields["SiteName"]) {
            $siteGroupingItem["SiteName"] = $newName
            Write-Host "Set SiteName to: $newName"
        }
        else {
            Write-Warning "SiteName field not found on Site Grouping item"
        }
        
        # Set TargetHostName and HostName
        if ($siteGroupingItem.Fields["TargetHostName"]) {
            $siteGroupingItem["TargetHostName"] = $hostName
            Write-Host "Set TargetHostName to: $hostName"
        }
        else {
            Write-Warning "TargetHostName field not found on Site Grouping item"
        }
        
        if ($siteGroupingItem.Fields["HostName"]) {
            $siteGroupingItem["HostName"] = $hostName
            Write-Host "Set HostName to: $hostName"
        }
        else {
            Write-Warning "HostName field not found on Site Grouping item"
        }
        
        # Set Database
        if ($siteGroupingItem.Fields["Database"]) {
            $siteGroupingItem["Database"] = "master"
            Write-Host "Set Database to: master"
        }
        else {
            Write-Warning "Database field not found on Site Grouping item"
        }
        
        # Set LinkProvider
        if ($siteGroupingItem.Fields["LinkProvider"]) {
            $siteGroupingItem["LinkProvider"] = "emeraldlinkprovider"
            Write-Host "Set LinkProvider to: emeraldlinkprovider"
        }
        else {
            Write-Warning "LinkProvider field not found on Site Grouping item"
        }
        
        # Clear boolean fields
        $fieldsToClear = @("CacheHTML", "AllowDebug", "EnablePartialHtmlCacheClear", "EnablePreview", "EnableWebEdit", "EnableDebugger")
        foreach ($fieldName in $fieldsToClear) {
            if ($siteGroupingItem.Fields[$fieldName]) {
                $siteGroupingItem[$fieldName] = ""
                Write-Host "Cleared $fieldName field"
            }
            else {
                Write-Warning "$fieldName field not found on Site Grouping item"
            }
        }
        
        # Set ItemLanguageFallback
        if ($siteGroupingItem.Fields["ItemLanguageFallback"]) {
            $siteGroupingItem["ItemLanguageFallback"] = "1"
            Write-Host "Set ItemLanguageFallback to: 1"
        }
        else {
            Write-Warning "ItemLanguageFallback field not found on Site Grouping item"
        }
        
        # Set Language
        if ($siteGroupingItem.Fields["Language"]) {
            $siteGroupingItem["Language"] = $Language
            Write-Host "Set Language to: $Language"
        }
        else {
            Write-Warning "Language field not found on Site Grouping item"
        }
        
        # Set Environment
        if ($siteGroupingItem.Fields["Environment"]) {
            $siteGroupingItem["Environment"] = $environmentName
            Write-Host "Set Environment to: $environmentName"
        }
        else {
            Write-Warning "Environment field not found on Site Grouping item"
        }
        
        # Set OtherProperties
        if ($siteGroupingItem.Fields["OtherProperties"]) {
            $siteGroupingItem["OtherProperties"] = $otherProperties
            Write-Host "Set OtherProperties to: $otherProperties"
        }
        else {
            Write-Warning "OtherProperties field not found on Site Grouping item"
        }
        
        $siteGroupingItem.Editing.EndEdit() >> $null
        Write-Host "Successfully updated Site Grouping item" -ForegroundColor Green
    }

    end {
        Write-Host "Cmdlet Update-SiteGrouping - End"
    }
}

function Update-DictionaryItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$SiteName
    )

    begin {
        Write-Host "Cmdlet Update-DictionaryItem - Begin"
        Import-Function Get-DictionaryItem
    }

    process {
        Write-Host "Cmdlet Update-DictionaryItem - Process"
        Write-Host "Updating Dictionary item for site: $($Site.Paths.Path)"
        
        # Get dictionary item
        $dictionaryItem = Get-DictionaryItem -CurrentItem $Site
        
        if (-not $dictionaryItem) {
            Write-Warning "Dictionary item not found for site: $($Site.Paths.Path)"
            return $null
        }
        
        Write-Host "Found Dictionary item: $($dictionaryItem.Paths.Path) (ID: $($dictionaryItem.ID))"
        
        # Rename dictionary item to {sitename}-Dictionary
        $dictionaryNewName = "$SiteName-Dictionary"
        Write-Host "Renaming Dictionary item to: $dictionaryNewName"
        $dictionaryItem.Editing.BeginEdit()
        $dictionaryItem.Name = $dictionaryNewName
        # Set DisplayName to the same value
        if ($dictionaryItem.Fields["__Display Name"]) {
            $dictionaryItem["__Display Name"] = $dictionaryNewName
            Write-Host "Set DisplayName to: $dictionaryNewName"
        }
        $dictionaryItem.Editing.EndEdit() >> $null
        Write-Host "Successfully renamed Dictionary item to: $dictionaryNewName" -ForegroundColor Green
        
        # Set Fallback Domain field
        $fallbackDomainId = "{F50FBAE6-E5E2-4E26-8C88-0208DB5F5EC3}"
        Write-Host "Setting Fallback Domain field to: $fallbackDomainId"
        $dictionaryItem.Editing.BeginEdit()
        if ($dictionaryItem.Fields["Fallback Domain"]) {
            $dictionaryItem["Fallback Domain"] = $fallbackDomainId
            Write-Host "Successfully set Fallback Domain field" -ForegroundColor Green
        }
        else {
            Write-Warning "Fallback Domain field not found on Dictionary item"
        }
        
        $dictionaryItem.Editing.EndEdit() >> $null
        Write-Host "Completed updating Dictionary item" -ForegroundColor Green
        
        return $dictionaryItem
    }

    end {
        Write-Host "Cmdlet Update-DictionaryItem - End"
    }
}