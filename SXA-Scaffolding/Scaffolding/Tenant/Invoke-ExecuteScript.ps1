function Invoke-ExecuteScript {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
        [Item]$ModuleDefinition,

	    [Parameter(Mandatory=$true, Position=1 )]
		[Item]$Tenant,

		[Parameter(Mandatory=$true, Position=2 )]
        [Item[]]$TenantTemplates,
        
        [Parameter(Mandatory=$false, Position=3)]
        [string]$ScriptFieldName = 'Script'
    )

	begin {
		Write-Verbose "Cmdlet Invoke-ExecuteScript - Begin"
	}

	process {
		Write-Verbose "Cmdlet Invoke-ExecuteScript - Process"
		try {
        	[Sitecore.Data.ID]$scriptID = $ModuleDefinition.Fields[$ScriptFieldName].Value
			[Item]$script = Get-Item -Path master: -ID $scriptID
		}
		catch [System.Exception] {
			Write-Error $_
			return
		}

        Write-Verbose "Executing script: $($script.Paths.Path)"
		Write-Verbose "Current tenant: $($Tenant.Paths.Path)"
		Write-Verbose "Tenant templates: $($TenantTemplates | %{$_.ID})"

		Invoke-Script $script
		try {
			Invoke-ModuleScriptBody $Tenant $TenantTemplates
		}
		catch [System.Exception] {
			Write-Error $_
		}
	}

	end {
		Write-Verbose "Cmdlet Invoke-ExecuteScript - End"
	}
}