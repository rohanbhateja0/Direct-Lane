Import-Function Get-SettingsItem

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
        Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates ([Sitecore.XA.Foundation.Multisite.Templates+Home]::ID.ToString()) | ? {
            $homeTemplate = $_
            $homeItem = Get-ChildItem -Path ($Site.Paths.Path) -Language $Site.Language | ? { $_.TemplateID -eq $homeTemplate.ID } | Select-Object -First 1
            $homeItem -ne $null
        } > $null        
        
        if($homeItem){
            if ($homeItem.'Title') {
                $homeItem.Fields.ReadAll()
                $homeItem.Fields.Name | ? { $homeItem."$($_)" -eq "`$name" } | % { $homeItem."$($_)" = $Site.Name }
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
    }
}