function Add-TenantTemplateRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$TenantLocation,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TenantName,

        [Parameter(Mandatory = $true, Position = 2 )]
        [Item]$TenantTemplateLocation
    )

    begin {
        Write-Verbose "Cmdlet Add-TenantTemplateRoot - Begin"
        Import-Function Add-FolderStructure
    }

    process {
        Write-Verbose "Cmdlet Add-TenantTemplateRoot - Process"
        $tenantTail = $TenantLocation.Paths.Path.Substring(("/sitecore/content").Length)
        $path = $TenantTemplateLocation.Paths.Path + $tenantTail + "/" + $TenantName
        Add-FolderStructure $path "Foundation/Experience Accelerator/Multisite/Project Folder"
    }

    end {
        Write-Verbose "Cmdlet Add-TenantTemplateRoot - End"
    }
}