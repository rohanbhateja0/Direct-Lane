<#
.SYNOPSIS
    Gets the number of roles and users from Sitecore.

.DESCRIPTION
    This script retrieves all roles and users from Sitecore and displays
    the total count of each, along with a summary of the security accounts.

.EXAMPLE
    # Run the script in Sitecore PowerShell ISE
    .\Get-RolesAndUsers.ps1
#>

begin {
	Write-Verbose "Cmdlet Get-RolesAndUsers - Begin"
}

process {
	Write-Verbose "Cmdlet Get-RolesAndUsers - Process"

	Write-Host "`nRetrieving roles and users from Sitecore..." -ForegroundColor Yellow
	Write-Host "================================================" -ForegroundColor Yellow

	try {
		# Get all roles from Sitecore
		Write-Host "`nRetrieving roles..." -ForegroundColor Cyan
		$allRoles = [Sitecore.Security.Accounts.RoleManager]::GetAllRoles()
		$roleCount = ($allRoles | Measure-Object).Count
		
		Write-Host "Retrieving users..." -ForegroundColor Cyan
		$allUsers = [Sitecore.Security.Accounts.UserManager]::GetAllUsers()
		$userCount = ($allUsers | Measure-Object).Count

		# Display summary
		Write-Host "`n================================================" -ForegroundColor Green
		Write-Host "SECURITY ACCOUNTS SUMMARY" -ForegroundColor Green
		Write-Host "================================================" -ForegroundColor Green
		Write-Host "Total Roles:  $roleCount" -ForegroundColor Cyan
		Write-Host "Total Users:  $userCount" -ForegroundColor Cyan
		Write-Host "================================================" -ForegroundColor Green

		# Display roles (optional detailed list)
		if ($roleCount -gt 0) {
			Write-Host "`nRoles:" -ForegroundColor Yellow
			$index = 1
			foreach ($role in $allRoles) {
				try {
					Write-Host "  [$index] $($role.Name)" -ForegroundColor Gray
					$index++
				}
				catch {
					Write-Host "  [$index] (Error retrieving role: $($_.Exception.Message))" -ForegroundColor Yellow
					$index++
				}
			}
		}
		else {
			Write-Host "`nNo roles found." -ForegroundColor Yellow
		}

		# Display users (optional detailed list)
		if ($userCount -gt 0) {
			Write-Host "`nUsers:" -ForegroundColor Yellow
			$index = 1
			foreach ($user in $allUsers) {
				try {
					$userName = $user.Name
					$isEnabled = if ($user.Profile.IsAdministrator -or $user.IsAdministrator) { "Admin" } else { "Standard" }
					Write-Host "  [$index] $userName ($isEnabled)" -ForegroundColor Gray
					$index++
					
					# Limit display to first 50 users to avoid overwhelming output
					if ($index -gt 50) {
						Write-Host "  ... and $($userCount - 50) more users" -ForegroundColor Gray
						break
					}
				}
				catch {
					Write-Host "  [$index] (Error retrieving user: $($_.Exception.Message))" -ForegroundColor Yellow
					$index++
				}
			}
		}
		else {
			Write-Host "`nNo users found." -ForegroundColor Yellow
		}

		# Return summary object
		return [PSCustomObject]@{
			RoleCount = $roleCount
			UserCount = $userCount
			Roles = $allRoles
			Users = $allUsers
		}
	}
	catch {
		Write-Error "Failed to retrieve roles and users: $($_.Exception.Message)"
		Write-Host "Error details: $($_.Exception.GetType().FullName)" -ForegroundColor Red
		if ($_.Exception.InnerException) {
			Write-Host "Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
		}
		return $null
	}
}

end {
	Write-Verbose "Cmdlet Get-RolesAndUsers - End"
}

