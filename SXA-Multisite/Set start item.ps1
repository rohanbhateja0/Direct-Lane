Import-Function Get-SettingsItem
Import-Function Test-ItemIsSiteDefinition

function Invoke-ModuleScriptBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$TenantTemplates		
    )

    begin {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Begin"
        Import-Function Get-ProjectTemplateBasedOnBaseTemplate
    }

    process {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Process"
        Write-Verbose "My site: $($Site.Paths.Path)"
        Write-Verbose "My tenant templates: $($TenantTemplates | %{$_.ID})"

        $settingsItem = Get-SettingsItem $Site
        $homeItem = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates ([Sitecore.XA.Foundation.Multisite.Templates+Home]::ID.ToString()) | % {
            $homeTemplate = $_
            Get-ChildItem -Path ($Site.Paths.Path) | ? { $_.TemplateID -eq $homeTemplate.ID } | Select-Object -First 1
        } | Select-Object -First 1
        
        if($homeItem){
            $siteDefinitionItem = Get-ChildItem -Recurse -Path ($settingsItem.Paths.Path) | ? { (Test-ItemIsSiteDefinition $_) -eq $true} | Select-Object -First 1
            $siteDefinitionItem.StartItem = $homeItem.ID    
        }
    }

    end {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
    }
}