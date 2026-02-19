function Get-RemovalConfirmation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$message
    )

    begin {
        Write-Verbose "Cmdlet Get-RemovalConfirmation - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-RemovalConfirmation - Process"
        if ((Show-Confirm -Title $message) -eq "yes") {
            $true
        }
        else {
            $false
        }
    }

    end {
        Write-Verbose "Cmdlet Get-RemovalConfirmation - End"
    }
}