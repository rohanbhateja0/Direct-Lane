function Test-ItemIsSiteSetup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$Item
    )
    
    begin {
        Write-Verbose "Cmdlet Test-ItemIsSiteSetup - Begin"
    }
    
    process {
        Write-Verbose "Cmdlet Test-ItemIsSiteSetup - Process"   
        [Sitecore.Data.ID]$pageDataTemplateID = [Sitecore.XA.Foundation.Scaffolding.Templates+_Dependencies]::ID
        [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item).InheritsFrom($pageDataTemplateID)
    } 
    
    end {
        Write-Verbose "Cmdlet Test-ItemIsSiteSetup - End"
    }
}