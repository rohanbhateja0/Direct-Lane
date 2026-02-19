function Get-Layer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Item
    )

    begin {
        Write-Verbose "Cmdlet Get-Layer - Begin"
    }

    process {
        $Layer = "Feature"
        if ($Item.Paths.LongID.Contains("{31C85853-D86D-46B0-A418-86DF28F7294F}")) {
            $Layer = "Foundation"
        }
        if ($Item.Paths.LongID.Contains("{0AF56F64-B5D7-473F-9497-1DC19265E494}")) {
            $Layer = "Project"
        }   
        $Layer
    }

    end {
        Write-Verbose "Cmdlet Get-Layer - End"
    }
}