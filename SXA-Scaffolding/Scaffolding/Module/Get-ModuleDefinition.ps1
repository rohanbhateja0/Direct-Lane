function Get-ModuleDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$Layer,
        [Parameter(Mandatory = $true, Position = 1 )]
        [string]$TemplateName
    )

    begin {
        Write-Verbose "Cmdlet Get-ModuleDefinition - Begin"
        Import-Function Get-UniqueItem
    }

    process {
        Write-Verbose "Cmdlet Get-ModuleDefinition - Process"
        $query = "/sitecore/system/Settings/$Layer//*[@@templatename='$TemplateName']"
        $definitions = Get-Item -Path master: -Language "*" -Query $query
        Get-UniqueItem $definitions | ? { $_.Enabled }
    }

    end {
        Write-Verbose "Cmdlet Get-ModuleDefinition - End"
    }
}