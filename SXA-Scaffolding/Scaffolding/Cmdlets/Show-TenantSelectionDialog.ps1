function Show-TenantSelectionDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$Tenants,

        [Parameter(Mandatory = $false, Position = 1 )]
        [string]$DialogTitle = "Tenant selection",
        
        [Parameter(Mandatory = $false, Position = 2 )]
        [string]$DialogDescription = "Please select tenants"
    )

    begin {
        Write-Verbose "Cmdlet Show-TenantSelectionDialog - Begin"
        Import-Function Get-TenantItem
    }

    process {
        Write-Verbose "Cmdlet Show-TenantSelectionDialog - Process"
        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary
        $Tenants | % { 
            $site = $_
            $tenant = Get-TenantItem $site
            $displayName = $site.Paths.Path.Replace($tenant.Parent.Paths.Path + "/", "")
            $dialogOptions.Add($displayName, $_.ID) 
        }
        
        $preSelectedDefinitions = $Tenants.ID
        
        $dialogParmeters = @()
        $dialogParmeters += @{ Name = "preSelectedDefinitions"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Tenants); Options = $dialogOptions; Editor = "checklist"; Tip = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectTheFeaturesWhichShouldBeUsedInTenant); Height = "330px"}

        $result = Read-Variable -Parameters $dialogParmeters `
            -Description $DialogDescription `
            -Title $DialogTitle `
            -Width 500 -Height 600 `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("OK")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) 

        if ($result -ne "ok" -or $dialogOptions.Count -eq 0) {
            Close-Window
            Exit
        } 
        $Tenants | ? {
            $preSelectedDefinitions.Contains($_.ID.ToString())
        }
    }

    end {
        Write-Verbose "Cmdlet Show-TenantSelectionDialog - End"
    }
}