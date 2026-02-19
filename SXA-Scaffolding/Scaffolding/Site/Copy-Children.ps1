function Copy-Children {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SourceRoot,
    
        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$DestinationRoot
    )
    
    begin {
        Write-Verbose "Cmdlet Copy-Children - Begin"
    }
    
    process {
        Write-Verbose "Cmdlet Copy-Children - Process"
        $SourceRoot.Children | ForEach-Object {
            $_.CopyTo($DestinationRoot, $_.Name) > $null
        }
    }
    
    end {
        Write-Verbose "Cmdlet Copy-Children - End"
    }
}