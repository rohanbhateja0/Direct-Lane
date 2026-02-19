function Update-FeatureField ($SiteItem, $ID) {
    [Sitecore.Data.ID[]]$newFeaturesList = $SiteItem.Modules.Split("|") | ? { [guid]::TryParse($_, [ref][guid]::Empty) } | % { $_ }
    $newFeaturesList += $ID
    $SiteItem.Modules = $newFeaturesList -join "|"
}

function Add-TenantModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TenantItem,
        
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Add-TenantModule - Begin"
        Import-Function Invoke-TenantAction
        Import-Function Get-Action
        Import-Function Get-TenantTemplate
        Import-Function Get-TenantTemplatesRoot
    }

    process {
        Write-Verbose "Cmdlet Add-TenantModule - Process"

        $percentage_start = 5
        $percentage_end = 100
        $percentage_diff = $percentage_end - $percentage_start
        foreach ($definitionItem in $DefinitionItems) {
            $currentIndex = $DefinitionItems.IndexOf($definitionItem)
            $percentComplete = ($percentage_start + 1.0 * $percentage_diff * ($currentIndex) / ($DefinitionItems.Count))
            $currentOperation = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::InstallingFeature)) -f $definitionItem._Name
            Write-Progress -Activity ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::AddingTenantFeature)) -CurrentOperation ($currentOperation) -PercentComplete $percentComplete
            $actions = $definitionItem | Get-Action
            try {
                foreach ($actionItem in $actions) {
                    Invoke-TenantAction $TenantItem $actionItem $TenantItem.Language.Name
                }
                Update-FeatureField $TenantItem $definitionItem.ID
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
        Write-Verbose "Cmdlet Add-TenantModule - End"
    }
}