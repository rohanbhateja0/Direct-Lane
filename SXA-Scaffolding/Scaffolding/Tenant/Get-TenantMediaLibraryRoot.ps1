function Get-TenantMediaLibraryRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$ContextItem
    )

    begin {
        Write-Verbose "Cmdlet Get-TenantMediaLibraryRoot - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-TenantMediaLibraryRoot - Process"
        $tenantItem = Get-TenantItem $ContextItem
        Get-Item -Path master: -ID $tenantItem.MediaLibrary
    }
    end {
        Write-Verbose "Cmdlet Get-TenantMediaLibraryRoot - End"
    }
}