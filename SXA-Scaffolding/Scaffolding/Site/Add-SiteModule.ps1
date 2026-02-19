Import-Function Get-ItemByIdSafe

function Get-EditingTheme ($SiteItem) {    
    $SettingsItem = Get-SettingsItem $SiteItem    
    $editingThemeID = $SettingsItem[[Sitecore.XA.Foundation.Theming.Templates+_EditingTheme+Fields]::Theme]
    Get-ItemByIdSafe $editingThemeID
}

function Get-SiteTheme ($SiteItem) {
    $defaultDeviceID = "{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}"
    $defaultDevice = Get-Item -Path . -ID $defaultDeviceID
    Get-ThemeItem $SiteItem $defaultDevice
}

function Update-FeatureField ($SiteItem, $ID) {
    $newFeaturesList = $SiteItem.Modules.Split("|") | ? { [guid]::TryParse($_, [ref][guid]::Empty) } | % { $_ }
    $newFeaturesList += $ID
    $SiteItem.Modules = $newFeaturesList -join "|"
}

function Add-SiteModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,
        
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Add-SiteModule - Begin"
        Import-Function Get-SortedSetupItemsCollection
        Import-Function Get-SettingsItem
        Import-Function Get-ThemeItem
        Import-Function Invoke-SiteAction
        Import-Function Get-Action
    }

    process {
        Write-Verbose "Cmdlet Add-SiteModule - Process"
        $DefinitionItems = Get-SortedSetupItemsCollection $DefinitionItems

        $siteTheme = Get-SiteTheme $Site
        $editingTheme = Get-EditingTheme $Site

        $percentage_start = 5
        $percentage_end = 100
        $percentage_diff = $percentage_end - $percentage_start
        foreach ($definitionItem in $DefinitionItems) {
            $currentIndex = $DefinitionItems.IndexOf($definitionItem)
            $percentComplete = ($percentage_start + 1.0 * $percentage_diff * ($currentIndex) / ($DefinitionItems.Count))
            $currentOperation = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InstallingFeature)) -f $definitionItem._Name
            Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddingSiteFeature)) -CurrentOperation ($currentOperation) -PercentComplete $percentComplete
            $actions = $definitionItem | Get-Action
            try {
                foreach ($actionItem in $actions) {
                    Invoke-SiteAction $Site $actionItem -SiteTheme $siteTheme -EditingTheme $editingTheme $Site.Language.Name
                }
                Update-FeatureField $Site $definitionItem.ID
            }
            catch {
                Write-Log -Log Error "An error occured while processing $($actionItem.Paths.Path) action"        
                $ErrorRecord = $Error[0]
                Write-Log -Log Error $ErrorRecord
                Close-Window
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Add-SiteModule - End"
    }
}