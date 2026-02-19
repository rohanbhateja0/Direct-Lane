function Get-Action {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item[]]$DefinitionItems
    )

    begin {
        Write-Verbose "Cmdlet Get-Action - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-Action - Process"
        $DefinitionItems | % {
            Write-Verbose "Processing definiiton: $($_.Paths.Path)"
            Get-ChildItem -Path $_.ProviderPath -Recurse | ? { 
                $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($_)
                $template -and $template.InheritsFrom('Action Base') 
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Get-Action - End"
    }
}