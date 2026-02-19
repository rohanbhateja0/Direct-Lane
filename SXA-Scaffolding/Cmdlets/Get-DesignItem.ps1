function Get-DesignItem{
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-PageDesignsItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-PageDesignsItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Presentation.IPresentationContext]).GetDesignItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item
	}

	end {
		Write-Verbose "Cmdlet Get-PageDesignsItem - End"
	}
}