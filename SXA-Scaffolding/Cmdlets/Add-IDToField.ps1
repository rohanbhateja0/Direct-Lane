function Add-IDToField {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0 )]
        [Sitecore.Data.Items.Item]$CurrentItem,
        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$FieldName,

        [Parameter(Mandatory=$true, Position=2)]
        [Sitecore.Data.ID]$ID
        )

	begin {
		Write-Verbose "Cmdlet Add-BaseTemplate - Begin"
	}

	process {
		Write-Verbose "Cmdlet Add-BaseTemplate - Process"
		try {
		    [Sitecore.Data.ID[]]$existingIds = New-Object  System.Collections.ArrayList
		    if(![string]::IsNullOrWhiteSpace($CurrentItem."$FieldName")) {
			    [Sitecore.Data.ID[]]$existingIds = $CurrentItem."$FieldName".Split('|') | ? { $_ -ne ""}
		    }
		
		    if($existingIds -contains $ID) {
		        Write-Verbose "Cmdlet Add-BaseTemplate - Base template $($ID) already present at $($CurrentItem.ID) template"
		        return
		    }
		    
		    $existingIds += $ID
			$newValue = $existingIds -join "|"
			$CurrentItem."$FieldName" = $newValue
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