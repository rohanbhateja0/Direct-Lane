function Get-DataItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-DataItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-DataItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.IMultisiteContext]).GetDataItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item
	}

	end {
		Write-Verbose "Cmdlet Get-DataItem - End"
	}
}