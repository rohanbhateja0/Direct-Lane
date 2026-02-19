function Get-AllSxaTenant {
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "Cmdlet Get-AllSxaTenant - Begin"
        Import-Function Get-AllSxaSite
        Import-Function Get-TenantItem
    }

    process {
        Write-Verbose "Cmdlet Get-AllSxaTenant - Process"
        $tenantPaths = @()
        Get-AllSxaSite | % {
            $sitePath = $_.Paths.Path
            $belongsToProcessedTenants = ($tenantPaths | ? { $sitePath.StartsWith($_) }) -ne $null
            if ($belongsToProcessedTenants -eq $false) {
                $tenantItem = Get-TenantItem $_
                $tenantPaths += $tenantItem.Paths.Path
                $tenantItem
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Get-AllSxaTenant - End"
    }
}