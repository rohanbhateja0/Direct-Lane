function Update-InsertOptions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$TemplateItem,
        [Parameter(Mandatory = $true, Position = 1 )]
        [Sitecore.Data.ID]$OldInsertOption,
        [Parameter(Mandatory = $true, Position = 2 )]
        [Sitecore.Data.ID]$NewInsertOption
    )

    begin {
        Write-Verbose "Cmdlet Set-InsertOptions - Begin"
    }

    process {
        Write-Verbose "Cmdlet Set-InsertOptions - Process"
        $svItem = $TemplateItem.Database.GetItem($TemplateItem.Fields["__Standard values"]) | Wrap-Item
        $svItem.__Masters = $svItem.__Masters.Replace($OldInsertOption,$NewInsertOption)
    }

    end {
        Write-Verbose "Cmdlet Set-InsertOptions - End"
    }
}