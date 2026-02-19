function Get-ItemWithModuleInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$Items,
        
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$SetupItem
    )

    begin {
        Write-Verbose "Cmdlet Get-ItemWithModuleInstalled - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-ItemWithModuleInstalled - Process"
        $Items | ? {
            $item = $_
            [Sitecore.Data.ID[]]$installedModules = $item.Modules.Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) }
            $null -ne $installedModules -and $installedModules.Contains($SetupItem.ID)
        }
    }

    end {
        Write-Verbose "Cmdlet Get-ItemWithModuleInstalled - End"
    }
}