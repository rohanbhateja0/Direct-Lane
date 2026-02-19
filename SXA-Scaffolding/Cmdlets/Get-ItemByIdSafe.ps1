function Get-ItemByIdSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0 )]
        [string]$idString,
        [Parameter(Mandatory = $false, Position = 1 )]
        [string]$lang
    )

    begin {
        Write-Verbose "Cmdlet Get-ItemByIdSafe - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-ItemByIdSafe - Process"
        [Sitecore.Data.ID]$id = $null
        if ([Sitecore.Data.ID]::TryParse($idString, [ref]$id) -and (Test-Path $id)) {
            if([string]::IsNullOrEmpty($lang)){
                Get-Item . -ID $id
            }else{
                Get-Item . -ID $id -Language $lang
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Get-ItemByIdSafe - End"
    }
}