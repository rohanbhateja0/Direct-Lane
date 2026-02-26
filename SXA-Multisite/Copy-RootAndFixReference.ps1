function Copy-RootAndFixReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Source,

        [Parameter(Mandatory = $true, Position = 1)]
        [Item]$Destination,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$CopyName
    )

    begin {
        Write-Verbose "Cmdlet Copy-RootAndFixReference - Begin"
        Import-Function Set-NewLinkReference        
    }

    process {
        Write-Verbose "Cmdlet Copy-RootAndFixReference - Process"
        $destinationItem = $Source.CopyTo($Destination, $CopyName)
        Set-NewLinkReference $Source $destinationItem
        $destinationItem
    }

    end {
        Write-Verbose "Cmdlet Copy-RootAndFixReference - End"
    }
}