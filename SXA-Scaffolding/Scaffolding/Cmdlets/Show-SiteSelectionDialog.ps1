function Show-SiteSelectionDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$Sites,
        
        [Parameter(Mandatory = $false, Position = 1 )]
        [string]$DialogTitle = "Site selection",
        
        [Parameter(Mandatory = $false, Position = 2 )]
        [string]$DialogDescription = "Please select sites"
    )

    begin {
        Write-Verbose "Cmdlet Show-SiteSelectionDialog - Begin"
        Import-Function Get-TenantItem
    }

    process {
        Write-Verbose "Cmdlet Show-SiteSelectionDialog - Process"
        $dialogOptions = New-Object System.Collections.Specialized.OrderedDictionary
        $Sites | % { 
            $site = $_
            $tenant = Get-TenantItem $site
            $displayName = $site.Paths.Path.Replace($tenant.Parent.Paths.Path + "/", "")
            $dialogOptions.Add($displayName, $_.ID) 
        }
        
        $preSelectedDefinitions = $Sites.ID
        
        $dialogParmeters = @()
        $dialogParmeters += @{ Name = "preSelectedDefinitions"; Title = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::Sites); Options = $dialogOptions; Editor = "checklist"; Tip = [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::SelectTheFeaturesWhichShouldBeUsedInTenant); Height = "330px"}

        $result = Read-Variable -Parameters $dialogParmeters `
            -Description $DialogDescription `
            -Title $DialogTitle `
            -Width 500 -Height 600 `
            -OkButtonName $([Sitecore.Globalization.Translate]::Text("OK")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) 

        if ($result -ne "ok" -or $dialogOptions.Count -eq 0) {
            Close-Window
            Exit
        } 
        $Sites | ? {
            $preSelectedDefinitions.Contains($_.ID.ToString())
        }
    }

    end {
        Write-Verbose "Cmdlet Show-SiteSelectionDialog - End"
    }
}