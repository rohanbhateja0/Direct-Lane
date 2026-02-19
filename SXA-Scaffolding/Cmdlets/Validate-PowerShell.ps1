function Test-PowerShellVersion {
	[CmdletBinding()]
    param()

	begin {
		Write-Verbose "Cmdlet Test-PowerShellVersion - Begin"
	}

	process {
		Write-Verbose "Cmdlet Test-PowerShellVersion - Process"
        -not ($PSVersionTable.PSVersion.Major -lt 3)
	}

	end {
		Write-Verbose "Cmdlet Test-PowerShellVersion - End"
	}
}

function Test-PowerShellExtensionsVersion {
	[CmdletBinding()]
    param()

	begin {
		Write-Verbose "Cmdlet Test-PowerShellExtensionsVersion - Begin"
	}

	process {
		Write-Verbose "Cmdlet Test-PowerShellExtensionsVersion - Process"
        $currentHost = Get-Host
        $requiredVersion = New-Object -TypeName "System.Version" -ArgumentList 4,3
        $currentVersion = $currentHost.Version
        $currentVersion -ge $requiredVersion
	}

	end {
		Write-Verbose "Cmdlet Test-PowerShellExtensionsVersion - End"
	}
}

function Show-PowerShellExtensionsVersionAlert {
	[CmdletBinding()]
    param()

	begin {
		Write-Verbose "Cmdlet Show-PowerShellExtensionsVersionAlert - Begin"
	}

	process {
		Write-Verbose "Cmdlet Show-PowerShellExtensionsVersionAlert - Process"
        $currentHost = Get-Host
        $currentVersion = $currentHost.Version
		$msg = "Experience Accelerator requires Sitecore PowerShell Extensions 4.3 or newer, your current version is $($currentVersion.Major).$($currentVersion.Minor). Please upgrade the module to gain access to this functionality."
        Write-Host -ForegroundColor Red $msg
        Show-Alert $msg
	}

	end {
		Write-Verbose "Cmdlet Show-PowerShellExtensionsVersionAlert - End"
	}
}

function Show-PowerShellVersionAlert {
	[CmdletBinding()]
    param()

	begin {
		Write-Verbose "Cmdlet Show-PowerShellVersionAlert - Begin"
	}

	process {
		Write-Verbose "Cmdlet Show-PowerShellVersionAlert - Process"
		$msg = "Your Powershell host version is not supported. Please upgrade to v3 or higher"
        Write-Host -ForegroundColor Red $msg
        Show-Alert $msg
	}

	end {
		Write-Verbose "Cmdlet Show-PowerShellVersionAlert - End"
	}
}


function Test-PowerShell {
	[CmdletBinding()]
    param()

	begin {
		Write-Verbose "Cmdlet Show-PowerShellVersionAlert - Begin"
	}

	process {
        if (-NOT (Test-PowerShellVersion)){
            Show-PowerShellVersionAlert
            Close-Window
            Exit
        }

        if (-NOT (Test-PowerShellExtensionsVersion)){
            Show-PowerShellExtensionsVersionAlert
            Close-Window
            Exit
        }
	}

	end {
		Write-Verbose "Cmdlet Show-PowerShellVersionAlert - End"
	}
}
