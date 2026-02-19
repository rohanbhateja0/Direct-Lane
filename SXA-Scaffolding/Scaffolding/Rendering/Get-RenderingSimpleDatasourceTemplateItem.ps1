function Get-RenderingSimpleDatasourceTemplateItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$DatasourceItem
    )

    begin {
        Write-Verbose "Cmdlet Get-RenderingSimpleDatasourceTemplateItem - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-RenderingSimpleDatasourceTemplateItem - Process"
        if ($DatasourceItem.Fields["__Standard values"]) {
            $svItem = $DatasourceItem.Database.GetItem($DatasourceItem.Fields["__Standard values"])
            if ($svItem -and $svItem.Fields["__Masters"]) {
                $DatasourceItem.Database.GetItem($svItem.Fields["__Masters"])    
            }    
        }        
    }

    end {
        Write-Verbose "Cmdlet Get-RenderingSimpleDatasourceTemplateItem - End"
    }
}