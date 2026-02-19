function New-SiteTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Sitecore.XA.Foundation.Scaffolding.Models.CreateNewSiteThemeModel]$Model,
        [Parameter(Mandatory = $false, Position = 1)]
        $plainThemeID = "{B43D07BD-61D5-448F-9323-8B6ACAD4F3C4}"
    )

    begin {
        Write-Verbose "Cmdlet New-SiteTheme - Begin"
        Import-Function Copy-Children
        Import-Function Get-Action
        Import-Function Get-SettingsItem
        Import-Function Invoke-EditTheme
        Import-Function Invoke-ExtendTheme
        Import-Function Get-SortedSetupItemsCollection
    }

    process {
        Write-Verbose "Cmdlet New-SiteTheme - Process"
        $plainTheme = Get-Item -Path master: -Id $plainThemeID
        $theme = Get-Item -Path master: -Id ([Sitecore.XA.Foundation.Theming.Templates+Theme]::ID)
        $siteTheme = New-Item -Parent $Model.ThemeLocation -ItemType $theme.Paths.FullPath -Name $Model.ThemeName -Language $Model.Language
        Copy-Children $plainTheme $siteTheme
        if ($Model.DefinitionItems) {
            $Model.DefinitionItems = Get-SortedSetupItemsCollection $Model.DefinitionItems
            $Model.DefinitionItems | Get-Action | ? { $_.TemplateName -eq "EditSiteTheme" } | % { Invoke-EditTheme $siteTheme $_ }
            $Model.DefinitionItems | Get-Action | ? { $_.TemplateName -eq "ExtendSiteTheme" } | % { Invoke-ExtendTheme $siteTheme $_ }
        }
        
        $addResolveConflictsThemeAction = Get-Item -Path master: -Id "{5833E633-A212-446F-A3D5-9D5455E6977D}"
        Invoke-EditTheme $siteTheme $addResolveConflictsThemeAction
        
        if ($Model.SiteLocation){
            $settingsItem = Get-SettingsItem $Model.SiteLocation
            $settingsItem.Themes = $settingsItem.Themes, $siteTheme.ID -join "|"
        }
        
        $siteTheme
    }

    end {
        Write-Verbose "Cmdlet New-SiteTheme - End"
    }
} 