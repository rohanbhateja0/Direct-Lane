function Get-TenantItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-TenantItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-TenantItem - Process"
		$instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.IMultisiteContext]).GetTenantItem($CurrentItem) | ? { $_ -ne $null}  | Wrap-Item
	}

	end {
		Write-Verbose "Cmdlet Get-TenantItem - End"
	}
}