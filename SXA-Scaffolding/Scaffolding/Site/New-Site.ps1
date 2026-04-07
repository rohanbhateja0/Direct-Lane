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
Import-Function Write-HostWithTimestamp


function Show-CBRENewSiteDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteLocation
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Show-NewSiteDialog - Begin"
        Import-Function Get-ForbiddenSiteName
        Import-Function Get-ValidSiteSetupDefinition
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::BuildingNewSiteDialog)) -PercentComplete 0
    }

    process {
        Write-HostWithTimestamp "Cmdlet Show-NewSiteDialog - Process"
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::GettingTenantTemplates)) -PercentComplete 20
        $tenantTemplatesRoot = Get-TenantTemplatesRoot $SiteLocation
        if ($tenantTemplatesRoot -eq $null) {
            Write-HostWithTimestamp "Site Collection Templates root could not be found for a given location: '$($SiteLocation.Paths.Path)'" -ForegroundColor Red
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

        # Pre-selected definitions are no longer used - all modules are included by default
        # $preSelectedDefinitions = $nonSystemDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IncludeByDefault']).Checked -eq $true } | % { $_.ID }

        $languages = [ordered]@{}
        Get-ChildItem -Path "/sitecore/system/languages" | % { $languages[$_.Name] = $_.Name } > $null

        $dialogOptions = Get-OrderedDictionaryByKey $dialogOptions
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::PreparingNewSiteDialog)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::OpeningNewSiteDialog)) -PercentComplete 100

        $siteName = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewSite)
        $hostName = "*"
        $virtualFolder = "/"
        $language = "en"
        $createNewTheme = $false
        $cloneExistingSite = $false
        # Site Template ID 
        $existingSite = Get-Item -Path master: -ID "{D33B2D5D-86D3-4F9B-B538-1F63B9A54A55}"

        #Bootstrap Grid Setup ID 4
        $gridSetupID = '{361E981F-8399-47F9-B5F1-2C27BA7BAC09}'
        $themeName = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteThemeName)

        # Existing Sites
        $existingSites = [ordered]@{}
        Get-ChildItem -Path "/sitecore/content/CBRE/Brands" | Where-Object { $_.TemplateName -eq "Site" } | ForEach-Object {
            $existingSites[$_.Name] = $_.ID
        }

        $existingSites = Get-OrderedDictionaryByKey $existingSites
        Write-HostWithTimestamp "Existing Sites: $($existingSites.Count)"

        # Parameters
        $parameters = @()
        $parameters += @{ Name = "siteName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }
        $parameters += @{ Name = "hostName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::HostName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }
        $parameters += @{ Name = "virtualFolder"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::VirtualFolder); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }
        $parameters += @{ Name = "language"; Options = $languages; Title = [Sitecore.Globalization.Translate]::Text("Language"); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General); }
        # Features tab is hidden - all modules will be included by default
        # if ($dialogOptions.Count -gt 0) {
        #     $parameters += @{ Name = "preSelectedDefinitions"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); Options = $dialogOptions; Editor = "checklist"; Tip = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectTheFeaturesWhichShouldBeUsedInSite); Height = "330px"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); }
        # }
        $parameters += @{ Name = "cloneExistingSite"; Title = "CLONE EXISTING SITE"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }
        $parameters += @{ Name = "createNewTheme"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreateNewTheme); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Theme) }
        $parameters += @{ Name = "themeName"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewThemeName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Theme) }
        $parameters += @{ Name = "validThemes"; Source = "DataSource=/sitecore/media library/Themes&DatabaseName=master&IncludeTemplatesForSelection=Theme"; editor = "treelist"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThemesUsableByThisSite); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Theme) }
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
            
            # Include all non-system modules by default (Features tab is hidden)
            Write-HostWithTimestamp "Adding all non-system modules (Features tab is hidden)"
            [Item[]]$allNonSystemDefinitionItems = ($nonSystemDefinitions | % { Get-Item -Path master: -ID $_.ID })
            if ($allNonSystemDefinitionItems) {
                $definitionItems.AddRange($allNonSystemDefinitionItems)
                Write-HostWithTimestamp "  - Added $($allNonSystemDefinitionItems.Count) non-system module(s)"
            }

            [Item[]]$systemFeatures = $allDefinitions | ? { ([Sitecore.Data.Fields.CheckboxField]$_.Fields['IsSystemModule']).Checked -eq $true }
            if ($systemFeatures) {
                Write-HostWithTimestamp "Adding system features"
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
                Write-HostWithTimestamp "Adding auto-included features"
                $definitionItems.AddRange($autoIncludedFeatures)
            }


            $gridSetupItem = Get-Item -Path master: -ID $gridSetupID
            if ($gridSetupItem) {
                Write-HostWithTimestamp "Adding grid feature"
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
        Write-HostWithTimestamp "Cmdlet Show-NewSiteDialog - End"
    }
}

function New-CBRESite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model
    )

    begin {
        Write-HostWithTimestamp "Cmdlet New-Site - Begin"
        Import-Function Invoke-SiteAction
        Import-Function New-MappingString
        Import-Function Add-SiteMediaLibrary
        Import-Function Select-InheritingFrom
        Import-Function Copy-CBRESite
        Import-Function Get-DictionaryItem
        Import-Function Get-SettingsItem
        Import-Function Get-SiteDefinitionDialogKey
        Import-Function Get-UniqueName
        Import-Function Get-ForbiddenSiteName
        Import-Function New-SiteTheme
        Import-Function Get-PageDesignsItem
    }

    process {
        Write-HostWithTimestamp "Cmdlet New-Site - Process"
        
        # Check if cloning is requested
        if ($Model.CloneExistingSite -and $Model.ExistingSite) {
            Write-HostWithTimestamp "Clone Existing Site is checked. Proceeding with site cloning..."
            Write-Progress -Activity "Cloning Site" -CurrentOperation "Getting source site" -PercentComplete 0
            
            # Get the source site item (it may be an Item object or an ID)
            if ($Model.ExistingSite -is [Sitecore.Data.Items.Item]) {
                $sourceSite = $Model.ExistingSite
            }
            else {
                $sourceSite = Get-Item -Path master: -ID $Model.ExistingSite
            }
            
            if (-not $sourceSite) {
                Write-Error "Source site not found: $($Model.ExistingSite)"
                return
            }
            
            Write-HostWithTimestamp "Source site: $($sourceSite.Paths.Path)"
            Write-HostWithTimestamp "Destination location: $($Model.SiteLocation.Paths.Path)"
            Write-HostWithTimestamp "New site name: $($Model.SiteName)"
            
            Write-Progress -Activity "Cloning Site" -CurrentOperation "Building site definition mapping" -PercentComplete 20
            
            # Build site definition mapping
            $mapping = New-Object -TypeName "System.Collections.Hashtable"
            $forbiddenSiteNames = Get-ForbiddenSiteName $Model.SiteLocation
            $settingsItem = Get-SettingsItem $sourceSite
            
            $sitegroupingItemTemplateId = "{9534A0CC-1055-4A4B-B624-05F2BE277211}"
            $siteItemTemplateId = "{2BB25752-B3BC-4F13-B9CB-38B906D21A33}"
            $sitesGroupingItem = $settingsItem.Children | Select-InheritingFrom $sitegroupingItemTemplateId | Select-Object -First 1
            
            if ($sitesGroupingItem) {
                $siteDefinitionNames = Get-ChildItem -Path $sitesGroupingItem.Paths.Path -Recurse | Select-InheritingFrom $siteItemTemplateId | % { $_.Name }
                Write-HostWithTimestamp "Found $($siteDefinitionNames.Count) site definition(s) to map"
                
                $siteDefinitionNames | ForEach-Object {
                    $siteDefinitionName = $_
                    $newName = Get-UniqueName "$($_)_clone" $forbiddenSiteNames
                    $mapping.Add($siteDefinitionName, $newName)
                    Write-HostWithTimestamp "  Mapping '$siteDefinitionName' -> '$newName'"
                }
            }
            else {
                Write-Warning "Site grouping item not found. Proceeding without site definition mapping."
            }
            
            Write-Progress -Activity "Cloning Site" -CurrentOperation "Copying site" -PercentComplete 40
            
            # Determine theme handling strategy:
            # 1. If CreateSiteTheme is checked and ThemeName is provided, create a new theme (skip cloning)
            # 2. Else if ValidThemes are provided, use existing themes (skip cloning)
            # 3. Otherwise, clone the theme folder as usual
            $useExistingThemes = $null
            $createNewTheme = $false
            
            if ($Model.CreateSiteTheme -and -not [string]::IsNullOrWhiteSpace($Model.ThemeName)) {
                Write-HostWithTimestamp "Create New Theme is checked with theme name '$($Model.ThemeName)' - will create a new theme instead of cloning theme folder"
                $createNewTheme = $true
                # Skip theme cloning by using empty UseExistingThemes array (tells Copy-CBRESite to create empty folder)
                $useExistingThemes = @()
            }
            elseif ($Model.ValidThemes -and $Model.ValidThemes.Count -gt 0) {
                Write-HostWithTimestamp "Existing themes selected - will use existing themes instead of cloning theme folder"
                $useExistingThemes = $Model.ValidThemes
            }
            
            # Clone the site using Copy-CBRESite function
            if ($null -ne $useExistingThemes) {
                $destinationSite = Copy-CBRESite -Site $sourceSite -Destination $Model.SiteLocation -CopyName $Model.SiteName -SiteDefinitionsMapping $mapping -UseExistingThemes $useExistingThemes
            }
            else {
                $destinationSite = Copy-CBRESite -Site $sourceSite -Destination $Model.SiteLocation -CopyName $Model.SiteName -SiteDefinitionsMapping $mapping
            }
            
            if ($destinationSite) {
                # Ensure the site item name matches the name from the dialog
                if ($destinationSite.Name -ne $Model.SiteName) {
                    Write-HostWithTimestamp "Renaming site item from '$($destinationSite.Name)' to '$($Model.SiteName)'"
                    $destinationSite.Editing.BeginEdit()
                    $destinationSite.Name = $Model.SiteName
                    $destinationSite.Editing.EndEdit() >> $null
                    # Refresh the item reference
                    $destinationSite = Get-Item -Path master: -ID $destinationSite.ID
                }
                
                Write-Progress -Activity "Cloning Site" -CurrentOperation "Updating dictionary" -PercentComplete 80
                
                # Handle dictionary renaming (same as Clone Site.ps1)
                $dictionary = Get-DictionaryItem $destinationSite
                if ($dictionary) {
                    Rename-Item -Path $dictionary.Paths.Path -NewName ([guid]::NewGuid().ToString("N"))
                    $dictionary."__Display Name" = "Dictionary"
                    Write-HostWithTimestamp "Dictionary renamed successfully"
                }
                
                Write-Progress -Activity "Cloning Site" -CurrentOperation "Finalizing" -PercentComplete 90
                
                # Update site definition with new hostname and virtual folder if provided
                $destinationSettingsItem = Get-SettingsItem $destinationSite
                if ($destinationSettingsItem) {
                    $siteDefinitionItem = Get-ChildItem -Recurse -Path ($destinationSettingsItem.Paths.Path) | ? { (Test-ItemIsSiteDefinition $_) -eq $true } | Select-Object -First 1
                    if ($siteDefinitionItem) {
                        # Update SiteName field to use the name from the dialog
                        $siteDefinitionItem.Editing.BeginEdit()
                        if ($Model.SiteName) {
                            $siteDefinitionItem.Fields["SiteName"].Value = $Model.SiteName
                            Write-HostWithTimestamp "Updated SiteName field to: $($Model.SiteName)"
                        }
                        if ($Model.HostName) {
                            $siteDefinitionItem.HostName = $Model.HostName
                        }
                        if ($Model.VirtualFolder) {
                            $siteDefinitionItem.VirtualFolder = $Model.VirtualFolder
                        }
                        if ($Model.Language) {
                            $siteDefinitionItem.Fields["Language"].Value = $Model.Language
                        }
                        $siteDefinitionItem.Editing.EndEdit() >> $null
                    }
                    
                    # Handle theme setup - matching normal site creation flow
                    Set-CBREClonedSiteThemes -Site $destinationSite -Model $Model -CreateNewTheme $createNewTheme -SettingsItem $destinationSettingsItem
                }
                
                # CBRE Post Site Creation Steps
                Write-Progress -Activity "Cloning Site" -CurrentOperation "Running post-deployment steps" -PercentComplete 95
                if ($destinationSettingsItem -and $siteDefinitionItem) {
                    $language = if ($Model.Language) { $Model.Language } else { "en" }
                    CBREPostSiteCreationStep -Site $destinationSite -SettingsItem $destinationSettingsItem -SiteDefinitionItem $siteDefinitionItem -Language $language
                }
                
                # Run Site Manager
                #Run-SiteManager
                
                Write-Progress -Activity "Cloning Site" -CurrentOperation "Complete" -PercentComplete 100
                Write-HostWithTimestamp "Site cloned successfully: $($destinationSite.Paths.Path)" -ForegroundColor Green
                return
            }
            else {
                Write-Error "Failed to clone site"
                return
            }
        }
        else {
            # Normal site creation flow
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

                    Write-HostWithTimestamp "Cmdlet Add-Site - Process"
                    Write-HostWithTimestamp "Creating site ($SiteName) under: $($SiteLocation.Paths.Path)"
                    Write-HostWithTimestamp "Definitions items count: $($DefinitionItems.Length)"
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

                    $siteThemesFolder = Get-CBRESiteThemesFolder $site
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
                    $editingTheme = New-CBREEditingTheme $siteThemesFolder "Editing Theme" $baseEditingThemeID $language
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
                    Initialize-CBREPresentation $site $tenantTemplates $language

                    Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SettingTenantTemplatesLocation)) -PercentComplete 99
                    Set-TenantTemplate $site $tenantTemplates
            
                    $site = $site.Database.GetItem($site.ID, $site.Language) | Wrap-Item
                    $site.Modules = $DefinitionItems.ID -join "|"            

                    # CBRE Post Site Creation Steps
                    CBREPostSiteCreationStep -Site $site -SettingsItem $settingsItem -SiteDefinitionItem $siteDefinitionItem -Language $language

                    Invoke-CBREPostSiteSetupStep $Model
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
    }
    end {
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::YourSiteHasBeenCreated)) -CurrentOperation "" -PercentComplete 100
        Write-HostWithTimestamp "Cmdlet New-Site - End"
    }
}

function Invoke-CBREPostSiteSetupStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Invoke-PostSiteSetupStep - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Invoke-PostSiteSetupStep - Process"
        Invoke-PostSetupStep $Model.DefinitionItems $Model
    }

    end {
        Write-HostWithTimestamp "Cmdlet Invoke-PostSiteSetupStep - End"
    }
}

function Invoke-CBREPreSiteCreationValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Invoke-PreSiteCreationValidation - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Invoke-PreSiteCreationValidation - Process"
        Invoke-InputValidationStep $Model.DefinitionItems $Model
    }

    end {
        Write-HostWithTimestamp "Cmdlet Invoke-PreSiteCreationValidation - End"
    }
}

function Initialize-CBREPresentation {
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
        Write-HostWithTimestamp "Cmdlet Initialize-Presentation - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Initialize-Presentation - Process"
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
        Write-HostWithTimestamp "Cmdlet Initialize-Presentation - End"
    }
}

function Get-CBRESiteThemesFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Get-SiteThemesFolder - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Get-SiteThemesFolder - Process"
        $TenantThemesFolder = Get-TenantThemesFolder $site

        $folderType = "/System/Media/Media folder"
        $folderName = $Site.Name

        $themesFolder = Get-ItemOrCreate $TenantThemesFolder $folderName $folderType
        return $themesFolder
    }

    end {
        Write-HostWithTimestamp "Cmdlet Get-SiteThemesFolder - End"
    }
}

function New-CBREEditingTheme {
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
        Write-HostWithTimestamp "Cmdlet New-EditingTheme - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet New-EditingTheme - Process"
        $baseTheme = Get-Item master: -ID ([Sitecore.XA.Foundation.Theming.Templates+BaseTheme]::ID)
        $siteTheme = New-Item -Parent $ThemeLocation -ItemType $baseTheme.Paths.Path  -Name $ThemeName  -Language $Language
        if ($BaseThemesID) {
            $siteTheme.BaseLayout = $BaseThemesID -join '|'
        }
        $siteTheme
    }

    end {
        Write-HostWithTimestamp "Cmdlet New-EditingTheme - End"
    }
}

function Set-CBREClonedSiteThemes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [CBRE.Feature.Pipelines.Scaffolding.CreateNewSiteModel]$Model,

        [Parameter(Mandatory = $true, Position = 2)]
        [bool]$CreateNewTheme,

        [Parameter(Mandatory = $true, Position = 3)]
        [Item]$SettingsItem
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Set-CBREClonedSiteThemes - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Set-CBREClonedSiteThemes - Process"
        
        $language = if ($Model.Language) { $Model.Language } else { "en" }
        $siteThemesFolder = Get-CBRESiteThemesFolder $Site
        $siteTheme = $null
        
        # Create new theme if requested (matching normal flow lines 514-523)
        if ($CreateNewTheme) {
            Write-HostWithTimestamp "Creating new theme '$($Model.ThemeName)'..." -ForegroundColor Cyan
            Write-Progress -Activity "Cloning Site" -CurrentOperation "Creating new theme" -PercentComplete 92
            
            $themeModel = New-Object Sitecore.XA.Foundation.Scaffolding.Models.CreateNewSiteThemeModel
            $themeModel.ThemeName = $Model.ThemeName
            $themeModel.SiteLocation = $Site
            $themeModel.ThemeLocation = $siteThemesFolder
            $themeModel.Language = $language
            $themeModel.DefinitionItems = $Model.DefinitionItems
            $siteTheme = New-SiteTheme $themeModel
            Write-HostWithTimestamp "  - Created new theme: $($siteTheme.Paths.Path)" -ForegroundColor Green
        }
        
        # Always create editing theme 
        Write-Progress -Activity "Cloning Site" -CurrentOperation "Creating editing theme" -PercentComplete 93
        $baseEditingThemeID = "{BB9FCC9B-9302-41B4-B75E-849A1870E6ED}"
        $editingTheme = New-CBREEditingTheme $siteThemesFolder "Editing Theme" $baseEditingThemeID $language
        $SettingsItem.EditingTheme = $editingTheme.ID
        Write-HostWithTimestamp "  - Created editing theme" -ForegroundColor Green
        
        # Handle ValidThemes if provided 
        if ($Model.ValidThemes) {
            Write-HostWithTimestamp "Updating site settings to use valid themes..." -ForegroundColor Cyan
            $defaultDeviceID = "{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}"
            $selectedValidThemes = ($Model.ValidThemes | ForEach-Object { $_.ID }) -join "|"
            
            # Clear existing themes before setting new ones
            $SettingsItem.Editing.BeginEdit()
            $SettingsItem.Themes = ""
            $SettingsItem.Themes = $selectedValidThemes
            $SettingsItem.Editing.EndEdit() >> $null
            
            $defaultThemeID = $Model.ValidThemes | ForEach-Object { $_.ID } | Select-Object -First 1
            $pageDesignsItem = Get-PageDesignsItem $Site
            if ($pageDesignsItem) {
                $pageDesignsItem.Editing.BeginEdit()
                $pageDesignsItem.Theme = ""
                $pageDesignsItem.Theme = New-MappingString @{"$defaultDeviceID" = "$defaultThemeID"; }
                $pageDesignsItem.Editing.EndEdit() >> $null
            }
            Write-HostWithTimestamp "  - Updated settings.Themes and Page Designs.Theme with valid themes" -ForegroundColor Green
        }
    }

    end {
        Write-HostWithTimestamp "Cmdlet Set-CBREClonedSiteThemes - End"
    }
}

function Set-CBREPageNotFoundLink {
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
        Write-HostWithTimestamp "Cmdlet Set-PageNotFoundLink - Begin"
        Import-Function Select-InheritingFrom
    }

    process {
        Write-HostWithTimestamp "Cmdlet Set-PageNotFoundLink - Process"
        Write-HostWithTimestamp "Starting to set Page Not Found Link (Error404Page) field..."
        Write-HostWithTimestamp "Found site: $($Site.Paths.Path) (ID: $($Site.ID))"
        Write-HostWithTimestamp "Searching for home item under site path: $($Site.Paths.Path) in language: $Language"
        $homeItem = Get-ChildItem -Path $Site.Paths.Path -Language $Language | Select-InheritingFrom ([Sitecore.XA.Foundation.Multisite.Templates+Page]::ID.ToString()) | Select-Object -First 1
        if ($homeItem) {
            Write-HostWithTimestamp "Found home item: $($homeItem.Paths.Path) (ID: $($homeItem.ID))"
            Write-HostWithTimestamp "Searching for 404 page under home item path: $($homeItem.Paths.Path)"
            $notFoundPage = Get-ChildItem -Path $homeItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "404" } | Select-Object -First 1
            if ($notFoundPage) {
                Write-HostWithTimestamp "Found 404 page: $($notFoundPage.Paths.Path) (ID: $($notFoundPage.ID))"
                Write-HostWithTimestamp "Setting Error404Page field on settings item: $($SettingsItem.Paths.Path)"
                $notFoundPagePath = $notFoundPage.Paths.Path
                Write-HostWithTimestamp "Setting droplink field value to path: $notFoundPagePath"
                $SettingsItem.Editing.BeginEdit()
                $SettingsItem.Fields["Error404Page"].Value = $notFoundPagePath
                $SettingsItem.Editing.EndEdit() >> $null
                Write-HostWithTimestamp "Successfully set Error404Page field to path: $notFoundPagePath" -ForegroundColor Green
            }
            else {
                Write-Warning "404 page not found under home item at: $($homeItem.Paths.Path)"
                Write-HostWithTimestamp "Available items under home: $((Get-ChildItem -Path $homeItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
            }
        }
        else {
            Write-Warning "Home item not found for site: $($Site.Paths.Path)"
            Write-HostWithTimestamp "Available items under site: $((Get-ChildItem -Path $Site.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
    }

    end {
        Write-HostWithTimestamp "Cmdlet Set-PageNotFoundLink - End"
    }
}

function Set-CBRESiteSettingsFields {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$SettingsItem
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Set-SiteSettingsFields - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Set-SiteSettingsFields - Process"
        Write-HostWithTimestamp "Setting additional site settings fields on: $($SettingsItem.Paths.Path)"
        
        $SettingsItem.Editing.BeginEdit()
        
        # Set SchemaLocation
        $schemaLocationPath = "/sitecore/content/CBRE/Shared/Shared Content/Data/Schema"
        Write-HostWithTimestamp "Setting SchemaLocation field to: $schemaLocationPath"
        if (Test-Path "master:$schemaLocationPath") {
            $SettingsItem.Fields["SchemaLocation"].Value = $schemaLocationPath
            Write-HostWithTimestamp "Successfully set SchemaLocation field to: $schemaLocationPath" -ForegroundColor Green
        }
        else {
            Write-Warning "SchemaLocation path not found: $schemaLocationPath"
        }
        
        # Set SharedContentLocation
        $sharedContentLocationPath = "/sitecore/content/CBRE/Shared/Shared Content/Home/Content"
        Write-HostWithTimestamp "Setting SharedContentLocation field to: $sharedContentLocationPath"
        if (Test-Path "master:$sharedContentLocationPath") {
            $SettingsItem.Fields["SharedContentLocation"].Value = $sharedContentLocationPath
            Write-HostWithTimestamp "Successfully set SharedContentLocation field to: $sharedContentLocationPath" -ForegroundColor Green
        }
        else {
            Write-Warning "SharedContentLocation path not found: $sharedContentLocationPath"
        }
        
        # Set SiteLanguages
        $enLanguageId = "{AF584191-45C9-4201-8740-5409F4CF8BDD}"
        Write-HostWithTimestamp "Setting SiteLanguages field to EN Language item ID: $enLanguageId"
        $enLanguageItem = Get-Item -Path master: -ID $enLanguageId -ErrorAction SilentlyContinue
        if ($enLanguageItem) {
            Write-HostWithTimestamp "Found EN Language item: $($enLanguageItem.Paths.Path) (ID: $($enLanguageItem.ID))"
            $SettingsItem.Fields["SiteLanguages"].Value = $enLanguageId
            Write-HostWithTimestamp "Successfully set SiteLanguages field to: $enLanguageId" -ForegroundColor Green
        }
        else {
            Write-Warning "EN Language item not found with ID: $enLanguageId"
        }
        
        $SettingsItem.Editing.EndEdit() >> $null
        Write-HostWithTimestamp "Completed setting site settings fields" -ForegroundColor Green
    }

    end {
        Write-HostWithTimestamp "Cmdlet Set-SiteSettingsFields - End"
    }
}

function Update-CBRESettingsItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$SettingsItem,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Language = "en"
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Update-SettingsItems - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet Update-SettingsItems - Process"
        Write-HostWithTimestamp "Updating settings items under: $($SettingsItem.Paths.Path)"
        
        # Rename HTML Snippets to HTML-Snippets
        $htmlSnippetsItem = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "HTML Snippets" } | Select-Object -First 1
        if ($htmlSnippetsItem) {
            Write-HostWithTimestamp "Found HTML Snippets item: $($htmlSnippetsItem.Paths.Path) (ID: $($htmlSnippetsItem.ID))"
            Write-HostWithTimestamp "Renaming 'HTML Snippets' to 'HTML-Snippets'"
            # $htmlSnippetsItem.Editing.BeginEdit()
            Rename-Item -Path $htmlSnippetsItem.Paths.Path -NewName "HTML-Snippets"
            # $htmlSnippetsItem.Editing.EndEdit() >> $null
            Write-HostWithTimestamp "Successfully renamed to: HTML-Snippets" -ForegroundColor Green
        }
        else {
            Write-Warning "HTML Snippets item not found under: $($SettingsItem.Paths.Path)"
            Write-HostWithTimestamp "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
        
        # Clear Privacy Warning Type field on Privacy Warning item
        $privacyWarningItem = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "Privacy Warning" } | Select-Object -First 1
        if ($privacyWarningItem) {
            Write-HostWithTimestamp "Found Privacy Warning item: $($privacyWarningItem.Paths.Path) (ID: $($privacyWarningItem.ID))"
            Write-HostWithTimestamp "Clearing Privacy Warning Type field"
            $privacyWarningItem.Editing.BeginEdit()
            $privacyWarningItem.Fields["PrivacyWarningType"].Value = ""
            $privacyWarningItem.Editing.EndEdit() >> $null
            Write-HostWithTimestamp "Successfully cleared Privacy Warning Type field" -ForegroundColor Green
        }
        else {
            Write-Warning "Privacy Warning item not found under: $($SettingsItem.Paths.Path)"
            Write-HostWithTimestamp "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
        
        # Update BrowserTitleScriban Template field
        $browserTitleFolder = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Where-Object { $_.Name -eq "Browser Title" } | Select-Object -First 1
        if ($browserTitleFolder) {
            Write-HostWithTimestamp "Found Browser Title folder: $($browserTitleFolder.Paths.Path) (ID: $($browserTitleFolder.ID))"
            $browserTitleScribanItem = Get-ChildItem -Path $browserTitleFolder.Paths.Path -Language $Language | Where-Object { $_.Name -eq "BrowserTitleScriban" } | Select-Object -First 1
            if ($browserTitleScribanItem) {
                Write-HostWithTimestamp "Found BrowserTitleScriban item: $($browserTitleScribanItem.Paths.Path) (ID: $($browserTitleScribanItem.ID))"
                Write-HostWithTimestamp "Updating Template field with: {{ cbre_metadata_title }}"
                $browserTitleScribanItem.Editing.BeginEdit()
                $browserTitleScribanItem.Fields["Template"].Value = "{{ cbre_metadata_title }}"
                $browserTitleScribanItem.Editing.EndEdit() >> $null
                Write-HostWithTimestamp "Successfully updated BrowserTitleScriban Template field" -ForegroundColor Green
            }
            else {
                Write-Warning "BrowserTitleScriban item not found under: $($browserTitleFolder.Paths.Path)"
                Write-HostWithTimestamp "Available items under Browser Title: $((Get-ChildItem -Path $browserTitleFolder.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
            }
        }
        else {
            Write-Warning "Browser Title folder not found under: $($SettingsItem.Paths.Path)"
            Write-HostWithTimestamp "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
        }
    }

    end {
        Write-HostWithTimestamp "Cmdlet Update-SettingsItems - End"
    }
}

function Update-CBRESiteGrouping {
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
        Write-HostWithTimestamp "Cmdlet Update-SiteGrouping - Begin"
        Import-Function Select-InheritingFrom
        Import-Function Get-DictionaryItem
    }

    process {
        Write-HostWithTimestamp "Cmdlet Update-SiteGrouping - Process"
        Write-HostWithTimestamp "Updating Site Grouping item under: $($SettingsItem.Paths.Path)"
        
        # Get site name first
        $siteName = $Site.Name
        if ($SiteDefinitionItem.SiteName -and $SiteDefinitionItem.SiteName -ne "*" -and $SiteDefinitionItem.SiteName -ne "`$name") {
            $siteName = $SiteDefinitionItem.SiteName
        }
        
        Write-HostWithTimestamp "Site Name: $siteName"
        
        # Find Site Grouping folder first
        [Sitecore.Data.ID]$_baseSiteGrouping = [Sitecore.XA.Foundation.Multisite.Templates+_BaseSiteGrouping]::ID
        $siteGroupingFolder = Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-InheritingFrom $_baseSiteGrouping | Select-Object -First 1
        
        if (-not $siteGroupingFolder) {
            Write-Warning "Site Grouping folder not found under: $($SettingsItem.Paths.Path)"
            Write-HostWithTimestamp "Available items under Settings: $((Get-ChildItem -Path $SettingsItem.Paths.Path -Language $Language | Select-Object -ExpandProperty Name) -join ', ')"
            return
        }
        
        Write-HostWithTimestamp "Found Site Grouping folder: $($siteGroupingFolder.Paths.Path) (ID: $($siteGroupingFolder.ID))"
        
        # Delete all items under the site grouping folder
        Write-HostWithTimestamp "Deleting all items under Site Grouping folder: $($siteGroupingFolder.Paths.Path)"
        $itemsToDelete = Get-ChildItem -Path $siteGroupingFolder.Paths.Path -Language $Language
        foreach ($itemToDelete in $itemsToDelete) {
            Write-HostWithTimestamp "Deleting item: $($itemToDelete.Paths.Path)"
            Remove-Item -Path $itemToDelete.Paths.Path -Recurse -Force
        }
        Write-HostWithTimestamp "Successfully deleted all items under Site Grouping folder" -ForegroundColor Green
        
        # Create new site grouping item based on the specified template
        $siteGroupingTemplateId = "{EDA823FC-BC7E-4EF6-B498-CD09EC6FDAEF}"
        Write-HostWithTimestamp "Creating new Site Grouping item with template: $siteGroupingTemplateId"
        $templateItem = Get-Item -Path master: -ID $siteGroupingTemplateId -ErrorAction SilentlyContinue
        if (-not $templateItem) {
            Write-Error "Template not found: $siteGroupingTemplateId"
            return
        }
        
        # Use the site name (without _clone if present) for the new item
        $newSiteGroupingName = $siteName -replace "_clone$", ""
        Write-HostWithTimestamp "Creating Site Grouping item with name: $newSiteGroupingName"
        $siteGroupingItem = New-Item -Parent $siteGroupingFolder -Name $newSiteGroupingName -ItemType $templateItem.Paths.Path -Language $Language
        Write-HostWithTimestamp "Successfully created new Site Grouping item: $($siteGroupingItem.Paths.Path)" -ForegroundColor Green
        
        # Update siteName to use the clean name (without _clone) for the rest of the function
        $siteName = $newSiteGroupingName
        
        # Get environment name from Sitecore configuration
        $environmentName = [Sitecore.Configuration.Settings]::GetSetting("XA.Foundation.Multisite.Environment")
        if ([string]::IsNullOrWhiteSpace($environmentName)) {
            Write-Warning "InstanceName setting not found, defaulting to PROD"
            $environmentName = "PROD"
        }
        
        Write-HostWithTimestamp "Site Name: $siteName"
        Write-HostWithTimestamp "Environment (from InstanceName): $environmentName"
        
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
        
        Write-HostWithTimestamp "Target HostName: $hostName"
        
        # Get dictionary item for OtherProperties
        $dictionaryItemId = (Get-DictionaryItem -CurrentItem $Site).ID.ToString()
        
        # Build new name and other properties
        $newName = "$siteName-$environmentName-Preview"
        Write-HostWithTimestamp "Renaming Site Grouping item to: $newName"
        
        # Build OtherProperties value
        $otherProperties = "dictionaryDomain=$dictionaryItemId"
        Write-HostWithTimestamp "OtherProperties: $otherProperties"
        
        # Update all fields
        Write-HostWithTimestamp "Setting fields on Site Grouping item"
        $siteGroupingItem.Editing.BeginEdit()


        # Set VirtualFolder field if empty or "/"
        $virtualFolder = $siteGroupingItem.Fields["VirtualFolder"].Value
        if ([string]::IsNullOrWhiteSpace($virtualFolder) -or $virtualFolder -eq "/") {
            $newVirtualFolder = "/$siteName"
            Write-HostWithTimestamp "Setting VirtualFolder field on Site Grouping item from '$virtualFolder' to: $newVirtualFolder"
            $siteGroupingItem.Fields["VirtualFolder"].Value = $newVirtualFolder
            Write-HostWithTimestamp "Successfully set VirtualFolder field to: $newVirtualFolder" -ForegroundColor Green
        }
        else {
            Write-HostWithTimestamp "VirtualFolder field already has value: $virtualFolder, skipping update"
        }

        # Set NeverPublish field
        if ($siteGroupingItem.Fields["__Never publish"]) {
            $siteGroupingItem["__Never publish"] = "1"
            Write-HostWithTimestamp "Set NeverPublish field to: 1" -ForegroundColor Green
        }
        else {
            Write-Warning "NeverPublish field not found on Site Grouping item"
        }

        # Rename the item
        $siteGroupingItem.Name = $newName
        
        # Set SiteName
        if ($siteGroupingItem.Fields["SiteName"]) {
            $siteGroupingItem["SiteName"] = $newName
            Write-HostWithTimestamp "Set SiteName to: $newName"
        }
        else {
            Write-Warning "SiteName field not found on Site Grouping item"
        }
        
        # Set TargetHostName and HostName
        if ($siteGroupingItem.Fields["TargetHostName"]) {
            $siteGroupingItem["TargetHostName"] = $hostName
            Write-HostWithTimestamp "Set TargetHostName to: $hostName"
        }
        else {
            Write-Warning "TargetHostName field not found on Site Grouping item"
        }
        
        if ($siteGroupingItem.Fields["HostName"]) {
            $siteGroupingItem["HostName"] = $hostName
            Write-HostWithTimestamp "Set HostName to: $hostName"
        }
        else {
            Write-Warning "HostName field not found on Site Grouping item"
        }
        
        # Set Database
        if ($siteGroupingItem.Fields["Database"]) {
            $siteGroupingItem["Database"] = "master"
            Write-HostWithTimestamp "Set Database to: master"
        }
        else {
            Write-Warning "Database field not found on Site Grouping item"
        }
        
        # Set LinkProvider
        if ($siteGroupingItem.Fields["LinkProvider"]) {
            $siteGroupingItem["LinkProvider"] = "emeraldlinkprovider"
            Write-HostWithTimestamp "Set LinkProvider to: emeraldlinkprovider"
        }
        else {
            Write-Warning "LinkProvider field not found on Site Grouping item"
        }
        
        # Clear boolean fields
        $fieldsToClear = @("CacheHTML", "AllowDebug", "EnablePartialHtmlCacheClear", "EnablePreview", "EnableWebEdit", "EnableDebugger")
        foreach ($fieldName in $fieldsToClear) {
            if ($siteGroupingItem.Fields[$fieldName]) {
                $siteGroupingItem[$fieldName] = ""
                Write-HostWithTimestamp "Cleared $fieldName field"
            }
            else {
                Write-Warning "$fieldName field not found on Site Grouping item"
            }
        }
        
        # Set ItemLanguageFallback
        if ($siteGroupingItem.Fields["ItemLanguageFallback"]) {
            $siteGroupingItem["ItemLanguageFallback"] = "1"
            Write-HostWithTimestamp "Set ItemLanguageFallback to: 1"
        }
        else {
            Write-Warning "ItemLanguageFallback field not found on Site Grouping item"
        }
        
        # Set Language
        if ($siteGroupingItem.Fields["Language"]) {
            $siteGroupingItem["Language"] = $Language
            Write-HostWithTimestamp "Set Language to: $Language"
        }
        else {
            Write-Warning "Language field not found on Site Grouping item"
        }
        
        # Set Environment
        if ($siteGroupingItem.Fields["Environment"]) {
            $siteGroupingItem["Environment"] = $environmentName
            Write-HostWithTimestamp "Set Environment to: $environmentName"
        }
        else {
            Write-Warning "Environment field not found on Site Grouping item"
        }
        
        # Set OtherProperties
        if ($siteGroupingItem.Fields["OtherProperties"]) {
            $siteGroupingItem["OtherProperties"] = $otherProperties
            Write-HostWithTimestamp "Set OtherProperties to: $otherProperties"
        }
        else {
            Write-Warning "OtherProperties field not found on Site Grouping item"
        }
        
        $siteGroupingItem.Editing.EndEdit() >> $null
        Write-HostWithTimestamp "Successfully updated Site Grouping item" -ForegroundColor Green
    }

    end {
        Write-HostWithTimestamp "Cmdlet Update-SiteGrouping - End"
    }
}

function Update-CBREDictionaryItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$SiteName
    )

    begin {
        Write-HostWithTimestamp "Cmdlet Update-DictionaryItem - Begin"
        Import-Function Get-DictionaryItem
    }

    process {
        Write-HostWithTimestamp "Cmdlet Update-DictionaryItem - Process"
        Write-HostWithTimestamp "Updating Dictionary item for site: $($Site.Paths.Path)"
        
        # Get dictionary item
        $dictionaryItem = Get-DictionaryItem -CurrentItem $Site
        
        if (-not $dictionaryItem) {
            Write-Warning "Dictionary item not found for site: $($Site.Paths.Path)"
            return $null
        }
        
        Write-HostWithTimestamp "Found Dictionary item: $($dictionaryItem.Paths.Path) (ID: $($dictionaryItem.ID))"
        
        # Rename dictionary item to {sitename}-Dictionary
        $dictionaryNewName = "$SiteName-Dictionary"
        Write-HostWithTimestamp "Renaming Dictionary item to: $dictionaryNewName"
        $dictionaryItem.Editing.BeginEdit()
        $dictionaryItem.Name = $dictionaryNewName
        # Set DisplayName to the same value
        if ($dictionaryItem.Fields["__Display Name"]) {
            $dictionaryItem["__Display Name"] = $dictionaryNewName
            Write-HostWithTimestamp "Set DisplayName to: $dictionaryNewName"
        }
        $dictionaryItem.Editing.EndEdit() >> $null
        Write-HostWithTimestamp "Successfully renamed Dictionary item to: $dictionaryNewName" -ForegroundColor Green
        
        # Set Fallback Domain field
        $fallbackDomainId = "{F50FBAE6-E5E2-4E26-8C88-0208DB5F5EC3}"
        Write-HostWithTimestamp "Setting Fallback Domain field to: $fallbackDomainId"
        $dictionaryItem.Editing.BeginEdit()
        if ($dictionaryItem.Fields["Fallback Domain"]) {
            $dictionaryItem["Fallback Domain"] = $fallbackDomainId
            Write-HostWithTimestamp "Successfully set Fallback Domain field" -ForegroundColor Green
        }
        else {
            Write-Warning "Fallback Domain field not found on Dictionary item"
        }
        
        $dictionaryItem.Editing.EndEdit() >> $null
        Write-HostWithTimestamp "Completed updating Dictionary item" -ForegroundColor Green
        
        return $dictionaryItem
    }

    end {
        Write-HostWithTimestamp "Cmdlet Update-DictionaryItem - End"
    }
}

function CBREPostSiteCreationStep {
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
        Write-HostWithTimestamp "Cmdlet CBREPostSiteCreationStep - Begin"
    }

    process {
        Write-HostWithTimestamp "Cmdlet CBREPostSiteCreationStep - Process"
        
        # Set Page Not Found Link to 404 page under home/404
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Setting Page Not Found Link" -PercentComplete 98
        Set-CBREPageNotFoundLink -Site $Site -SettingsItem $SettingsItem -Language $Language

        # Set additional site settings fields
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Setting Site Settings Fields" -PercentComplete 99
        Set-CBRESiteSettingsFields -SettingsItem $SettingsItem

        # Rename HTML Snippets and clear Privacy Warning Type field
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Updating Settings Items" -PercentComplete 99
        Update-CBRESettingsItems -SettingsItem $SettingsItem -Language $Language

        # Update Site Grouping item
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Updating Site Grouping" -PercentComplete 99
        Update-CBRESiteGrouping -Site $Site -SettingsItem $SettingsItem -SiteDefinitionItem $SiteDefinitionItem -Language $Language

        # Update Dictionary item
        Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreatingNewSite)) -CurrentOperation "Updating Dictionary Item" -PercentComplete 99
        $siteNameForDict = $Site.Name
        if ($SiteDefinitionItem.SiteName -and $SiteDefinitionItem.SiteName -ne "*" -and $SiteDefinitionItem.SiteName -ne "`$name") {
            $siteNameForDict = $SiteDefinitionItem.SiteName
        }
        Update-CBREDictionaryItem -Site $Site -SiteName $siteNameForDict
    }

    end {
        Write-HostWithTimestamp "Cmdlet CBREPostSiteCreationStep - End"
    }
}