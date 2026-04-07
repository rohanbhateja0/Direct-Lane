function Copy-CBRERootAndFixReference {
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
        Write-Host "Cmdlet Copy-CBRERootAndFixReference - Begin"
        Import-Function Set-CBRENewLinkReference        
    }

    process {
        Write-Host "Cmdlet Copy-CBRERootAndFixReference - Process"
        Write-Host "  - Copying item from: $($Source.Paths.Path) to: $($Destination.Paths.Path) with name: $CopyName"
        $destinationItem = $Source.CopyTo($Destination, $CopyName)
        Write-Host "  - Item copied successfully to: $($destinationItem.Paths.Path)" -ForegroundColor Green
        Write-Host "  - Fixing link references..."
        Set-CBRENewLinkReference $Source $destinationItem
        Write-Host "  - Link references fixed" -ForegroundColor Green
        $destinationItem
    }

    end {
        Write-Host "Cmdlet Copy-CBRERootAndFixReference - End"
    }
}