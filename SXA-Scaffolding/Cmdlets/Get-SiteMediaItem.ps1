function Get-SiteMediaItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-SiteMediaItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-SiteMediaItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.IMultisiteContext]).GetSiteMediaItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item
	}

	end {
		Write-Verbose "Cmdlet Get-SiteMediaItem - End"
	}
}