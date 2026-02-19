function Get-DictionaryItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$CurrentItem
    )

	begin {
		Write-Verbose "Cmdlet Get-DictionaryItem - Begin"
	}

	process {
		Write-Verbose "Cmdlet Get-DictionaryItem - Process"
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Multisite.IMultisiteContext]).GetDictionaryItem($CurrentItem) | ? { $_ -ne $null} | Wrap-Item    
	}

	end {
		Write-Verbose "Cmdlet Get-DictionaryItem - End"
	}
}