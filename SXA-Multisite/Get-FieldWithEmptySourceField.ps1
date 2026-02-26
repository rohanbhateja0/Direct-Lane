function Get-FieldWithEmptySourceField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0 )]
        [string]$StartPath = "/sitecore/templates/Project"
    )

    begin {
        Write-Verbose "Cmdlet Get-FieldWithEmptySourceField - Begin"      
        Import-Function Get-FieldSourceMapping
        Import-Function Get-ItemByIdSafe
    }

    process {
        $mapping = Get-FieldSourceMapping
        Write-Verbose "Cmdlet Get-FieldWithEmptySourceField - Process"
        $db = Get-Database "master"
        $db.DataManager.DataSource.SelectIDs($null,"455A3E98-A627-4B40-8035-E683A0331AC7", "1EB8AE32-E190-44A6-968D-ED904C794EBF", "", $alse) `
            | % { Get-ItemByIdSafe $_ } `
            | ? { $mapping.Contains($_.Type) } `
            | ? { $_.Paths.Path.StartsWith($StartPath) } `
            | Sort-Object @{Expression = {$_.Type}}
    }
    end {
        Write-Verbose "Cmdlet Get-FieldWithEmptySourceField - End"
    }
}