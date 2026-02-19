function Get-ItemWithoutModuleInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$Items,
        
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$SetupItem
    )

    begin {
        Write-Verbose "Cmdlet Get-ItemWithoutModuleInstalled - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-ItemWithoutModuleInstalled - Process"
        $Items | ? {
            $item = $_
            [Sitecore.Data.ID[]]$installedModules = $item.Modules.Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) }
            $installedModules -eq $null -or -not($installedModules.Contains($SetupItem.ID))
        }
    }

    end {
        Write-Verbose "Cmdlet Get-ItemWithoutModuleInstalled - End"
    }
}