function Get-TenantThemesFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ContextItem
    )

    begin {
        Write-Verbose "Cmdlet Get-TenantThemesFolder - Begin"
        Import-Function Get-TenantItem
    }

    process {
        Write-Verbose "Cmdlet Get-TenantThemesFolder - Process"
        $tenantItem = Get-TenantItem $ContextItem
        Get-Item -Path master: -ID $tenantItem.Themes
    }
    end {
        Write-Verbose "Cmdlet Get-TenantThemesFolder - End"
    }
}