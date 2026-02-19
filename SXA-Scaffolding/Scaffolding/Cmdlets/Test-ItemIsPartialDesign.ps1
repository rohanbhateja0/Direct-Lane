function Test-ItemIsPartialDesign {
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, Position=0 )]
		[Item]$Item
        )

	begin {
		Write-Verbose "Cmdlet Test-ItemIsPartialDesign - Begin"
	}

	process {
		Write-Verbose "Cmdlet Test-ItemIsPartialDesign - Process"   
		[Sitecore.Data.ID]$PartialDesignTemplateID = [Sitecore.XA.Foundation.Presentation.Templates+MetadataPartialDesign]::ID
        [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item).InheritsFrom($PartialDesignTemplateID)
	} 

	end {
		Write-Verbose "Cmdlet Test-ItemIsPartialDesign - End"
	}
}