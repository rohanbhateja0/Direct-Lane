Import-Function Get-TenantItem
Import-Function Get-SettingsItem
Import-Function Get-ItemOrCreate
Import-Function Get-Action
Import-Function Get-SiteDefinitions
Import-Function Get-SortedSetupItemsCollection
Import-Function Invoke-EditTheme
Import-Function New-SiteTheme
Import-Function Test-IsEditThemeModule
    
function Show-NewThemeDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ContextItem
    )
    
    begin {
        Write-Verbose "Cmdlet Show-NewThemeDialog - Begin"
    }
    
    process {

        $tenantItem = Get-TenantItem $ContextItem
        $settingsItem = Get-SettingsItem $ContextItem
    
        $TenantMediaLibraryID = $tenantItem.Themes
        if ($TenantMediaLibraryID) {
            $TenantMediaLibrary = Get-Item -Path master: -ID $TenantMediaLibraryID
            $siteName = $settingsItem.Parent.Name
            $mediaFolderType = "System/Media/Media folder"
            $ThemeLocation = Get-ItemOrCreate $TenantMediaLibrary $siteName $mediaFolderType
        }
        else {
            $editingThemeID = $settingsItem.EditingTheme
            if ($editingThemeID) {
                $editingTheme = Get-Item -Path master: -ID $editingThemeID
                $ThemeLocation = $editingTheme.Parent
                $TenantMediaLibrary = $ThemeLocation.Parent
            }
        }
    		
        if (-not($TenantMediaLibrary)) {
            Write-Log -Log Warning "Tenant folder for new theme was not resolved correctly. Check settings at your tenant item $($tenantItem.Paths.Path)"
            $TenantMediaLibrary = $tenantItem.MediaLibrary
            $ThemeLocation = $TenantMediaLibrary
        }                    

        [Item[]]$allDefinitions = Get-SiteDefinitions "*"
        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary
    
        $allDefinitions | ? { Test-IsEditThemeModule $_ } | % {
            $key = "$($_.Fields['Name'].Value)"
            if ($dialogOptions.Contains($key)) {
                $index = 2
                do {
                    $key = $key + " [$index]"
                    $index++
                } while ($dialogOptions.Contains($key))
            }
            $translatedFeatureName = [Sitecore.Globalization.Translate]::Text($key)
            $dialogOptions.Add($translatedFeatureName, $_.ID)
        }
    
        $preSelectedDefinitions = $allDefinitions | % { $_.ID }
    
        Write-Verbose "Cmdlet Show-NewThemeDialog - Process"
        $result = Read-Variable -Parameters `
        @{ Name = "themeName"; Value = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SiteThemeName); Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::NewThemeName); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General) }, `
        @{ Name = "preSelectedDefinitions"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); Options = $dialogOptions; Editor = "checklist"; Tip = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectTheFeaturesWhichShouldBeUsedInSite); Height = "330px"; Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Features); }, `
        @{ Name = "themeLocation"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThemeLocation); Root = $($TenantMediaLibrary.Paths.Path); Tab = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::General)} `
            -Description $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ThisScriptWillCreateANewFullyFunctionalSiteWithinYourSxaEnabledInstance)) `
            -Title $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::CreateANewExperienceAcceleratorSiteTheme)) -Width 500 -Height 600 `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("Ok")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `
            -Validator {
            $themeName = $variables.themeName.Value;
            $pattern = "^[\w][\w\s\-]*(\(\d{1,}\)){0,1}$"
            if ($themeName.Length -gt 100) {
                $variables.themeName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.Texts]::ThelengthofthevalueistoolongPleasespecifyavalueoflesstha)) -f 100
                continue
            }
            if ([System.Text.RegularExpressions.Regex]::IsMatch($themeName, $pattern, [System.Text.RegularExpressions.RegexOptions]::ECMAScript) -eq $false) {
                $variables.themeName.Error = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::IsNotAValidName)) -f $themeName
                continue
            }
        }
    
        if ($result -ne "ok") {
            Close-Window
            Exit
        }
    
        $definitionItems = New-Object System.Collections.ArrayList($null)
        if ($preSelectedDefinitions ) {
            Write-Verbose "Adding pre-selected features"
            [Item[]]$preSelectedDefinitions = ($preSelectedDefinitions | % { Get-Item -Path master: -ID $_ })
            $definitionItems.AddRange($preSelectedDefinitions)
        }
    
        $model = New-Object Sitecore.XA.Foundation.Scaffolding.Models.CreateNewSiteThemeModel
        $model.ThemeName = $themeName.TrimEnd(" ")
        $model.ThemeLocation = $themeLocation
        $model.SiteLocation = $ContextItem
        if ($definitionItems) {
            [System.Collections.Generic.List[Item]]$sortedDefinitionItems = Get-SortedSetupItemsCollection $definitionItems
            if ($sortedDefinitionItems) {
                $model.DefinitionItems = $sortedDefinitionItems    
            }            
        }
        $model.Language = [Sitecore.Context]::Language.Name
        $model
    }
    
    end {
        Write-Verbose "Cmdlet Show-NewThemeDialog - End"
    }
}