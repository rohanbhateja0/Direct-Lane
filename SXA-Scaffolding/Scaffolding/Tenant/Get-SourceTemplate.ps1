function Get-SourceTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Get-SourceTemplate - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-SourceTemplate - Process"
        $allActions = Get-Action $DefinitionItems
        [Sitecore.Data.ID[]]$tenantScriptDefinitionTemplates = $allActions  | ? { $_.TemplateName -eq "EditTenantTemplate" } | % { Get-Item -Path master: -ID $_.Fields['Template'].Value } | Sort-Object ID -Unique | % { $_.Template.ID.ToString() }

        $tenantScriptDefinitionTemplates | Sort-Object -Unique
    }

    end {
        Write-Verbose "Cmdlet Get-SourceTemplate - End"
    }
}