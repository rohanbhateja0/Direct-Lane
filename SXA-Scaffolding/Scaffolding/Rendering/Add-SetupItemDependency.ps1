function Add-SetupItemDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteSetupItem,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Sitecore.Data.ID]$DependencyId
    )

    begin {
        Write-Verbose "Cmdlet Add-SetupItemDependency - Begin"
    }

    process {
        Write-Verbose "Cmdlet Add-SetupItemDependency - Process"
        if ($SiteSetupItem."Dependencies".Contains($DependencyId) -eq $false) {
            if ($SiteSetupItem."Dependencies" -eq "") {
                $SiteSetupItem."Dependencies" = "$DependencyId"
            }
            else {
                $SiteSetupItem."Dependencies" = $SiteSetupItem."Dependencies", "$DependencyId" -join "|"
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Add-SetupItemDependency - End"
    }
}