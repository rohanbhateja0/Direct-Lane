function Add-BaseTemplate {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [Sitecore.Data.Items.TemplateItem]$TemplateItem,
        
        [Parameter(Mandatory=$true, Position=1)]
        [Sitecore.Data.Items.TemplateItem]$BaseTemplate
        )

	begin {
		Write-Verbose "Cmdlet Add-BaseTemplate - Begin"
	}

	process {
		Write-Verbose "Cmdlet Add-BaseTemplate - Process"
		$innerItem = $TemplateItem.InnerItem | Wrap-Item
		try {
		    [Sitecore.Data.ID[]]$baseTemplates = New-Object  System.Collections.ArrayList
		    if(![string]::IsNullOrWhiteSpace($innerItem."__Base template")) {
			    [Sitecore.Data.ID[]]$baseTemplates = $innerItem."__Base template".Split('|') | ? { $_ -ne ""}
		    }
		
		    if($baseTemplates -contains $BaseTemplate.ID) {
		        Write-Verbose "Cmdlet Add-BaseTemplate - Base template $($BaseTemplate.ID) already present at $($innerItem.ID) template"
		        return
		    }
		    
		    $baseTemplates += $BaseTemplate.ID
			$newValue = $baseTemplates -join "|"
			$innerItem."__Base template" = $newValue
		}
		catch [System.Exception] {
			Write-Error $_			
			return
		}
	}

	end {
		Write-Verbose "Cmdlet Add-BaseTemplate - End"
	}
}