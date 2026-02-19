function Get-PartialDesignsItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-PartialDesignsItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-PartialDesignsItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Presentation.IPresentationContext]).GetPartialDesignsItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item
	}

	end {
		Write-Verbose "Cmdlet Get-PartialDesignsItem - End"
	}
}