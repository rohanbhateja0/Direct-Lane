function Get-UniqueName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1 )]
        [string[]]$ForbiddenNames
    )

    begin {
        Write-Verbose "Cmdlet Get-UniqueName - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-UniqueName - Process"        
        $proposedName = $Name
        $index = 1
        while ($ForbiddenNames.Contains($proposedName)) {
            $proposedName = $Name + $index
            $index++
        }
        $proposedName
    }

    end {
        Write-Verbose "Cmdlet Get-UniqueName - End"
    }
}