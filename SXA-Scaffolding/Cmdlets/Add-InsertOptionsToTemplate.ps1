Import-Function Add-InsertOptionsToItem

function Add-InsertOptionsToTemplate {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [Sitecore.Data.Items.TemplateItem]$TemplateItem,
        
        [Parameter(Mandatory=$true, Position=1)]
        [Sitecore.Data.ID[]]$InsertOptions
        )

	begin {
		Write-Verbose "Cmdlet Add-InsertOptionsToTemplate - Begin"
	}

	process {
		Write-Verbose "Cmdlet Add-InsertOptionsToTemplate - Process"
        if($TemplateItem.StandardValues -eq $null){
			Write-Verbose "SV Item does not exits. Creating"
            $standardValuesItem = $TemplateItem.CreateStandardValues()
        }else{
			Write-Verbose "Taking existing SV item"
            $standardValuesItem = $TemplateItem.InnerItem.Children | ? { $_.Name -eq "__Standard Values" } | select -First 1 | Wrap-Item
        }		
		Add-InsertOptionsToItem -item $standardValuesItem -insertOptions $InsertOptions
	}

	end {
		Write-Verbose "Cmdlet Add-InsertOptionsToTemplate - End"
	}
}