function Get-SiteItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-SiteItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-SiteItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.IMultisiteContext]).GetSiteItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item  
	}

	end {
		Write-Verbose "Cmdlet Get-SiteItem - End"
	}
}