function Get-ModuleActionItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$ModuleItem
    )

    begin {
        Write-Verbose "Cmdlet Get-ModuleActionItem - Begin"
        Import-Function Get-Action
    }

    process {
        Write-Verbose "Cmdlet Get-ModuleActionItem - Process"
        $ModuleItem.Modules.Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) } | % { Get-Item master: -ID $_ } | Get-Action
    }

    end {
        Write-Verbose "Cmdlet Get-ModuleActionItem - End"
    }
}