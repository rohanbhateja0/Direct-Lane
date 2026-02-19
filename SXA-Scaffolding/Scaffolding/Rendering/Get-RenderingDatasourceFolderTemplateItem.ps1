function Get-RenderingDatasourceFolderTemplateItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$DatasourceItem
    )

    begin {
        Write-Verbose "Cmdlet Get-RenderingDatasourceFolderTemplateItem - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-RenderingDatasourceFolderTemplateItem - Process"
        $datasourceItemId = $DatasourceItem.ID
        $query = "/sitecore/templates//*[@@name = '__Standard Values' and Contains(@__Masters, '$datasourceItemId')]"
        Get-Item -Path master: -Language "*" -Query $query | Select-Object -First 1 | % {
            $svItemId = $_.ID
            $query = "/sitecore/templates//*[Contains(@__Standard values, '$svItemId')]"    
            Get-Item -Path master: -Language "*" -Query $query | Select-Object -First 1
        }
    }

    end {
        Write-Verbose "Cmdlet Get-RenderingDatasourceFolderTemplateItem - End"
    }
}