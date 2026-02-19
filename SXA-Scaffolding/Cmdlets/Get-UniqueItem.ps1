function Get-UniqueItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [Item[]]$Items
    )

    begin {
        Write-Verbose "Cmdlet Get-UniqueItem - Begin"
        Import-Function Select-SingleItemFromEachGroup
    }

    process {
        if($Items){
            $Items |  Group-Object ID | Select-SingleItemFromEachGroup | Wrap-Item
        }
    }

    end {
        Write-Verbose "Cmdlet Get-UniqueItem - End"
    }
}