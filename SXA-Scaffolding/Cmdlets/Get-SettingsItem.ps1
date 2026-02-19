function Get-SettingsItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-SettingsItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-SettingsItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.IMultisiteContext]).GetSettingsItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item
	}

	end {
		Write-Verbose "Cmdlet Get-SettingsItem - End"
	}
}