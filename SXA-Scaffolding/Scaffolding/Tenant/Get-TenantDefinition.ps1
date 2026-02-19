function Get-TenantDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [string]$Layer
    )

    begin {
        Write-Verbose "Cmdlet Get-TenantDefinition - Begin"
		Import-Function Select-SingleItemFromEachGroup
		Import-Function Get-ModuleDefinition
    }

    process {
        Write-Verbose "Cmdlet Get-TenantDefinition - Process"
		Get-ModuleDefinition $Layer "TenantSetupRoot"
    }

    end {
        Write-Verbose "Cmdlet Get-TenantDefinition - End"
    }
}