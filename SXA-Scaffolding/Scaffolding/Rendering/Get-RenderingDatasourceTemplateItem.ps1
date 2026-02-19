function Get-RenderingDatasourceTemplateItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$RenderingItem
    )

    begin {
        Write-Verbose "Cmdlet Get-RenderingDatasourceTemplateItem - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-RenderingDatasourceTemplateItem - Process"
        $RenderingItem = $RenderingItem | Wrap-Item
        $datasourceItemPath = $RenderingItem."Datasource Template"
        $datasourceItem = $null
        if ($datasourceItemPath) {
            $datasourceItem = $RenderingItem.Database.GetItem($datasourceItemPath) | Wrap-Item
            $datasourceItem
        }
    }

    end {
        Write-Verbose "Cmdlet Get-RenderingDatasourceTemplateItem - End"
    }
}
