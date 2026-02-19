function Add-TenantMediaLibrary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Tenant,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$ProjectMediaLibrary
    )

    begin {
        Write-Verbose "Cmdlet Add-TenantMediaLibrary - Begin"
        Import-Function Add-FolderStructure
    }

    process {
        $tenantTail = $Tenant.Paths.Path.Substring(("/sitecore/content").Length)
        $path = $ProjectMediaLibrary.Paths.Path + $tenantTail
        Add-FolderStructure $path
    }

    end {
        Write-Verbose "Cmdlet Add-TenantMediaLibrary - End"
    }
}