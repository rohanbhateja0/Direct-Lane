function Set-POS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$siteDefinition
    )

    begin {
        Write-Verbose "Cmdlet Set-POS - Begin"
    }

    process {
        Write-Verbose "Cmdlet Set-POS - Process"
        $siteDefinition `
        | ? { $_.Fields.Contains([Sitecore.XA.JSS.Foundation.Multisite.Templates+JSSSiteDefinition+Fields]::POS) } `
        | % { $_.POS = [string]::Empty }
    }

    end {
        Write-Verbose "Cmdlet Set-POS - End"
    }
}