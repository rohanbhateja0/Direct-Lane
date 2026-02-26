function Invoke-AddItem {
	[CmdletBinding()]
    param(
	    [Parameter(Mandatory=$true, Position=0 )]
		[Item]$Tenant,

	    [Parameter(Mandatory=$true, Position=1 )]
        [Item]$ModuleDefinition,

		[Parameter(Mandatory=$false, Position=2 )]
		[string]$Language="en"
    )

	begin {
		Write-Host "Cmdlet Invoke-AddItem - Begin"
	}

	process {
		Write-Host "Cmdlet Invoke-AddItem - Process"
        [Item]$location = Get-Item -Path master: -ID ($ModuleDefinition.Fields['Location'].Value)
        [Item]$template = Get-Item -Path master: -ID ($ModuleDefinition.Fields['Template'].Value)
        [string]$name = $ModuleDefinition.Fields['Name'].Value
        [System.Collections.Specialized.NameValueCollection]$fieldsMapping = [System.Web.HttpUtility]::ParseQueryString($($ModuleDefinition.Fields['Fields'].Value))
        Write-Host "Module definition: $($ModuleDefinition.Paths.Path)"

        $rootItem = Get-ChildItem -Path $Tenant.Paths.Path -Recurse -WithParent | ? { 
            $currentItemTemplate = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($_)
            if($currentItemTemplate){
                $currentItemTemplate.InheritsFrom($location.Template.ID) 
            }else{
                $false
            }
        } | Select -First 1
        
		if ($rootItem) {
			Write-Host "Found root item: $($rootItem.Paths.Path)"
			Write-Host "Checking whether item already exists"
			$templateTemp = $template
			if([Sitecore.Data.Managers.TemplateManager]::GetTemplate($template).InheritsFrom([Sitecore.TemplateIDs]::BranchTemplate)){
			    $templateTemp = $template.Children | Select-Object -First 1
			    if($templateTemp){
			        $templateTemp = $templateTemp.Template
			    }
			}
			$existingItem = $rootItem.Children | ? { $_.TemplateID -eq $templateTemp.ID } | ? { $_.Name -eq $name }
			if(-not $existingItem){
				Write-Host "Adding item, Name: $($name), Template: $($template.Paths.Path)"
				$newItem =  New-Item -Parent $rootItem -Name $name -ItemType $template.Paths.Path -Language $Language
				foreach($key in $fieldsMapping.AllKeys){
					$newItem."$($key)" = $fieldsMapping[$key]
				}
			}
		}
	}

	end {
		Write-Host "Cmdlet Invoke-AddItem - End"
	}
}