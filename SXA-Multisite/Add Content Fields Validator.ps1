function Invoke-ModuleScriptBody {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$Tenant,

		[Parameter(Mandatory=$true, Position=1 )]
        [Item[]]$TenantTemplates		
    )

	begin {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - Begin"
	}

	process {
        $result = $false
        [Sitecore.Data.ID]$pageTemplateID = [Sitecore.XA.Foundation.Multisite.Templates+Page]::ID
        $pageTemplate = $TenantTemplates | `
                ? { $_."__Base template".Contains($pageTemplateID) } | `
                ? { $_.Children.Count -gt 1 } | `
                Select-Object -First 1
        if($pageTemplate){
            $contentSection = $pageTemplate.Children | ? { $_.Name -eq "Content" }
            if($contentSection){
                $titleField = $contentSection.Children | Wrap-Item | ? { $_.Name -eq "Title" -and $_."Type" -eq "Single-Line Text" }
                $contentField = $contentSection.Children | Wrap-Item | ? { $_.Name -eq "Content" -and $_."Type" -eq "Rich Text"  }    
                if($titleField -and $contentField){
                    $result = $true
                }
            }
        }
        $result
	}

	end {
		Write-Verbose "Cmdlet Invoke-ModuleScriptBody - End"
	}
}