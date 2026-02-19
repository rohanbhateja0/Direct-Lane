function Select-SingleItemFromEachGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 , ValueFromPipeline = $true)]
        [Microsoft.PowerShell.Commands.GroupInfo]$GroupsOfItems
    )

    begin {
        Write-Verbose "Cmdlet Select-SingleItemFromEachGroup - Begin"
    }

    process {
        Write-Verbose "Cmdlet Select-SingleItemFromEachGroup - Process"
        $langSpecific = $GroupsOfItems.Group | ? { $_.Language.Name -eq $SitecoreContextItem.Language.Name }
        if ($langSpecific) {
            $langSpecific | Select-Object -First 1
        }
        else {
            $GroupsOfItems.Group | Select-Object -First 1
        }
    }

    end {
        Write-Verbose "Cmdlet Select-SingleItemFromEachGroup - End"
    }
}