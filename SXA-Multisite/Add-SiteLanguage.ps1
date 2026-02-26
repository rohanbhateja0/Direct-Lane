function Add-SiteLanguage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$Site,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$SourceLanguage,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$TargetLanguage
    )

    begin {
        Write-Verbose "Cmdlet Add-SiteLanguage - Begin"
        Import-Function Test-InDelegatedArea
    }

    process {
        Write-Verbose "Cmdlet Add-SiteLanguage - Process"

        $Site = Get-Item -Path $Site.Paths.Path -Language $SourceLanguage
        Get-ChildItem -Path $Site.Paths.Path -Recurse -WithParent | ForEach-Object {
            if(!(Test-InDelegatedArea $_)){
                Add-ItemLanguage -Item $_ -TargetLanguage $TargetLanguage -Language $SourceLanguage -IfExist Skip
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Add-SiteLanguage - End"
    }
}