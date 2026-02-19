function Get-AllSxaSiteDefinition {
    [CmdletBinding()]
    param()
    
    begin {
        Write-Verbose "Cmdlet Get-AllSxaSiteDefinition - Begin"
        Import-Function Get-AllSxaSite
        Import-Function Get-SettingsItem
        Import-Function Select-InheritingFrom
        [Sitecore.Data.ID]$siteGroupingTemplateId = "{11F57D7B-CBB2-4647-B98C-71457564BA4F}"
        [Sitecore.Data.ID]$siteDefinitionTemplateId = "{EDA823FC-BC7E-4EF6-B498-CD09EC6FDAEF}"
    }
    
    process {
        Write-Verbose "Cmdlet Get-AllSxaSiteDefinition - Process"   
        Get-AllSxaSite | % {
            $siteItem = $_
            $settingsItem = Get-SettingsItem $siteItem
            [Sitecore.Data.ID]$siteGroupingTemplateId = "{11F57D7B-CBB2-4647-B98C-71457564BA4F}"
            $siteGroupings = $settingsItem.Children | Select-InheritingFrom $siteGroupingTemplateId
            $siteGroupings.Children | Select-InheritingFrom $siteDefinitionTemplateId | Wrap-Item
        }
    } 
    
    end {
        Write-Verbose "Cmdlet Get-AllSxaSiteDefinition - End"
    }
}