begin {
	Write-Verbose "Cmdlet SIB Scaffloding - Begin"
}
process {
	Write-Verbose "Cmdlet Add-SiteLanguage - Process"

	##Pop-UP
	$mainItem = Get-Item .
	$mainHomeItem = $mainItem.paths.fullpath + "/Home"
	$mainHomeChildItems = Get-ChildItem -path $mainHomeItem
	if ($mainHomeChildItems.count -lt 5) {
		
		$targetPath = Get-Item -path $mainHomeItem
		$sourceItem = Get-Item "/sitecore/content/CBRE/Template/Site Template/Home"		
		$SourceLanguage = "en"
		$targetLanguages = [ordered]@{}
		$deleteLangauge = $false
        
		Get-ChildItem -Path "/sitecore/system/languages" | ForEach-Object { 
			$cutureInfo = [Sitecore.Globalization.Language]::CreateCultureInfo($_.Name)
			$displayName = [Sitecore.Globalization.Language]::GetDisplayName($cutureInfo)            
			$targetLanguages[$displayName] = $_.Name
		} | Out-Null
        

		$result = Read-Variable -Parameters `
		@{ Name = "targetLanguage"; Options = $targetLanguages; Value = "en"; Title = $([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::AddSiteLanguageDialogTargetLanguage)); } , `
		@{ Name = "deleteLangauge"; Title = "Select to delete english Language Version"; Editor = "Checkbox" }`
			-Description "Add Site in a box Template" `
			-Title "Site in a box setup" -Width 500 -Height 600 `
			-OkButtonName $([Sitecore.Globalization.Translate]::Text("Ok")) -CancelButtonName $([Sitecore.Globalization.Translate]::Text("Cancel")) `

		if ($result -ne "ok") {
			Close-Window
			Exit
		}
		else {
		
			try {
				#Copy
		
				$SourceItemsList = Get-ChildItem -Path $sourceItem.Paths.Fullpath -WithParent

				$SibNavPath = $null
				foreach ($sItem in $SourceItemsList) {
				
					if ($sItem.Name -eq "404") {
						$errorPageExist = Test-Path -path ($targetPath.Paths.Fullpath + "/" + $sItem.Name)
						if ($errorPageExist) {
							$errorPage = gi -path ($targetPath.Paths.Fullpath + "/" + $sItem.Name)
							$errorPagefields = Get-ItemField -path ($targetPath.Paths.Fullpath + "/" + $sItem.Name)
							$errorPage.Editing.BeginEdit()
							foreach ($field in $errorPagefields) {
								$errorPage[$field] = $sItem[$field]
							}				
							$errorPage.Editing.EndEdit()			
						
						
						}
						else {
							Copy-Item -path $sItem.Paths.Fullpath -Destination $targetPath.Paths.Fullpath	-Recurse

						}
					
					}
					elseif ($sItem.Name -eq "Home") {
						$homePage = gi -path $targetPath.Paths.Fullpath
						$homepagefields = Get-ItemField -path $targetPath.Paths.Fullpath
		
						$homePage.Editing.BeginEdit()
						foreach ($field in $homepagefields) {
							$homePage[$field] = $sItem[$field]
						}
						
						$homePage.Editing.EndEdit()
					}
					else {
						Copy-Item -path $sItem.Paths.Fullpath -Destination $targetPath.Paths.Fullpath	-Recurse
					}
				}		
			

				$sopath = $targetPath.Paths.Fullpath -replace "/Home", "/"
				$headerPath = $sopath + "/Data/Global-Navigation/Header/NavLinks"
				$footerPath = $sopath + "/Data/Footer/Footer"
				$pageDesignItems = $sopath + "Presentation/Page Designs"
				$testPageDesigExist = Test-Path -path $pageDesignItems
				if ($testPageDesigExist) {
					$pageDesigItem = gi -path $pageDesignItems
					$pageDesigItem.Editing.BeginEdit()
					$pageDesigItem["TemplatesMapping"] = ""
					$pageDesigItem.Editing.EndEdit()
				}
				
				#CopyGlobal Listings
				$targetGLpath = $sopath + "/Data/Global Listings/"
				$sourceGLpathItems = Get-ChildItem -Path "/sitecore/content/CBRE/Template/Site Template/Data/Global Listings"
				foreach ($sourceGLpathItem in $sourceGLpathItems) {
					Copy-Item -path $sourceGLpathItem.Paths.Fullpath -Destination $targetGLpath	-Recurse
				}
				#Copy Social Share
				$targetSSpath = $sopath + "/Settings/Social-Media-Groups"
				$iStargetSSpathExist = Test-Path -path $targetSSpath
				if (!$iStargetSSpathExist) {
					$oldtargetSSpath = $sopath + "/Settings/Social Media Groups"
					$oldtargetSSpathItem = gi -path $oldtargetSSpath
					$oldtargetSSpathItem.Editing.BeginEdit()
					$oldtargetSSpathItem.Name = "Social-Media-Groups"
					$oldtargetSSpathItem.Editing.EndEdit()
				
				}
				$sourceSSpathItems = gi -Path "/sitecore/content/CBRE/Template/Site Template/Settings/Social-Media-Groups/Social-Share" 
			
				Copy-Item -path $sourceSSpathItems.Paths.Fullpath -Recurse  -Destination $targetSSpath 
			
				#Copy Search Site Settings
				$targetSearchSpath = $sopath + "/Settings/Coveo-Site-Settings"
				$sSettingpathExists = Test-Path -path $targetSearchSpath
				if (!$sSettingpathExists) {
					$oldSearchSpath = $sopath + "/Settings/Coveo Site Settings"
					$oldSearchSpathItem = gi -path $oldSearchSpath
					$oldSearchSpathItem.Editing.BeginEdit()
					$oldSearchSpathItem.Name = "Coveo-Site-Settings"
					$oldSearchSpathItem.Editing.EndEdit()
				}
				$sourceSearchSpathItems = Get-ChildItem -Path "/sitecore/content/CBRE/Template/Site Template/Settings/Coveo-Site-Settings"
				foreach ($sourceSearchSpathItem in $sourceSearchSpathItems) {
					Copy-Item -path $sourceSearchSpathItem.Paths.Fullpath -Destination $targetSearchSpath	-Recurse
				}
			
				#CopyLink
				function updateNavitems( $placeholder) {
					$spath = $targetPath.Paths.Fullpath -replace "/Home", "/"				
					$globalNavPath
					$SibNavPath
				
					if ($placeholder -eq "Header") {
						$globalNavPath = Get-ChildItem -Path "/sitecore/content/CBRE/Template/Site Template/Data/Global-Navigation/Header/NavLinks" 			
						$SibNavPath = $spath + "/Data/Global-Navigation/Header/NavLinks"
					}
					elseif ($placeholder -eq "Footer") {
						$globalNavPath = Get-ChildItem -Path "/sitecore/content/CBRE/Template/Site Template/Data/Footer/Footer" 			
						$SibNavPath = $spath + "/Data/Footer/Footer"
					}
					Write-Verbose "$($SibNavPath)"
					Get-ChildItem -Path $SibNavPath | ForEach-Object { $_ | Remove-Item -Recurse }     
					foreach ($gitem in $globalNavPath) {
							   

						Copy-Item -path $gitem.Paths.Fullpath -Destination $SibNavPath	-Recurse

					}

					$SibNavItems = Get-ChildItem -path $SibNavPath -Recurse

					foreach ($item in $SibNavItems) {
						if ($item.TemplateId -eq "{C7E93343-9631-477A-B58C-2EDFC4359CCE}") {
							

							[Sitecore.Data.Fields.LinkField]$Cfield = $item.Fields["CTA"]
							if ($Cfield -ne "") {
								if ($Cfield.TargetID -ne "{00000000-0000-0000-0000-000000000000}") {
									$navItem = $null
									$navItem = gi -path $Cfield.TargetID
									$newPath = $null
									$navItem.paths.Fullpath
									if ($navItem.paths.Fullpath -like "/sitecore/content/CBRE/Template/Site Template/*") {
										$newPath = $navItem.paths.Fullpath -replace "/sitecore/content/CBRE/Template/Site Template/", $spath
										$exist = Test-Path -path $newPath
										if ($exist) {
											$newItem = gi -path $newPath
								
											$item.Editing.BeginEdit()
											$Cfield.TargetID = $newItem.Id
											$item.Editing.EndEdit()
										}
										else {
											$item | Remove-Item -Recurse
										}
									}
								}
							
							}
						}
					
						elseif ($item.TemplateId -eq "{EBED6E7E-036B-44D2-B170-6F363FB78987}" -or $item.TemplateId -eq "{2E77A8E5-F22A-4174-A01A-F03ABEAF084F}") {
								  

							[Sitecore.Data.Fields.LinkField]$Lfield = $item.Fields["Link"]
							if ($Lfield -ne "") {
								$navItem = $null
								if ($Lfield.TargetID -ne "{00000000-0000-0000-0000-000000000000}") {
									$navItem = gi -path $Lfield.TargetID
									$newPath = $null
									$navItem.paths.Fullpath
									if ($navItem.paths.Fullpath -like "/sitecore/content/CBRE/Template/Site Template/*") {
										$newPath = $navItem.paths.Fullpath -replace "/sitecore/content/CBRE/Template/Site Template/", $spath
										$exist = Test-Path -path $newPath
										if ($exist) {
											$newItem = gi -path $newPath
									
											$item.Editing.BeginEdit()
											$Lfield.TargetID = $newItem.Id
											$item.Editing.EndEdit()
										}
										else {
											$item | Remove-Item -Recurse
										}
									}
								}
							}
						}

					}


					if ($placeholder -eq "Footer") {
						$globalfooterpath = "/sitecore/content/CBRE/Template/Site Template/Data/Footer/Footer" 			
						$SibNavPath = $spath + "/Data/Footer/Footer"

						$footerPrimaryLinkpath = $SibNavPath + "/Footer-Primary-Links"
						$primaryList = Get-ChildItem -Path $footerPrimaryLinkpath
						$primaryIDs = ""
						foreach ($pItem in $primaryList) {
							$primaryIDs = $primaryIDs + $pItem.Id + "|"
						}

						$footerSecondaryLinkpath = $SibNavPath + "/Footer-Secondary-Links"
						$SecondaryList = Get-ChildItem -Path $footerSecondaryLinkpath
						$SecondaryIDs = ""
						foreach ($sItem in $SecondaryList) {
							$SecondaryIDs = $SecondaryIDs + $sItem.Id + "|"
						}



						$footerSocialLinkpath = $SibNavPath + "/Footer-Social-Links"
						$SocialList = Get-ChildItem -Path $footerSocialLinkpath
						$SocialIDs = ""
						foreach ($soItem in $SocialList) {
							$SocialIDs = $SocialIDs + $soItem.Id + "|"
						}

						$siItem = gi -path $SibNavPath
						$giItem = gi -path $globalfooterpath

						$siItem.Editing.BeginEdit()
						$siItem["PrimaryLinks"] = $primaryIDs.TrimEnd('|')
						$siItem["SecondaryLinks"] = $SecondaryIDs.TrimEnd('|')
						$siItem["SocialLinks"] = $SocialIDs.TrimEnd('|')
						$siItem["CopyrightText"] = $giItem["CopyrightText"]

						$siItem.Editing.EndEdit()
					}
				}
			
				updateNavitems "Header"
				updateNavitems "Footer"
			
		
				##Language
				if ($targetLanguage -ne "en") {
				
					$Site = Get-Item -Path $targetPath.Paths.Fullpath -Language $SourceLanguage
					Get-ChildItem -Path $Site.Paths.Fullpath -Recurse -WithParent | ForEach-Object {
								
						Add-ItemLanguage -Item $_ -TargetLanguage $targetLanguage -Language $SourceLanguage
					}
				
					$Data = Get-Item -Path $headerPath -Language $SourceLanguage
					Get-ChildItem -Path $Data.Paths.Fullpath -Recurse -WithParent | ForEach-Object {
								
						Add-ItemLanguage -Item $_ -TargetLanguage $targetLanguage -Language $SourceLanguage
					}
				
					$Datafoo = Get-Item -Path $footerPath -Language $SourceLanguage
					Get-ChildItem -Path $Datafoo.Paths.Fullpath -Recurse -WithParent | ForEach-Object {
								
						Add-ItemLanguage -Item $_ -TargetLanguage $targetLanguage -Language $SourceLanguage
					}
				
					$DataGL = Get-Item -Path $targetGLpath -Language $SourceLanguage
					Get-ChildItem -Path $DataGL.Paths.Fullpath -Recurse -WithParent | ForEach-Object {
								
						Add-ItemLanguage -Item $_ -TargetLanguage $targetLanguage -Language $SourceLanguage
					}	
				
				
				
				
				}
				if ($deleteLangauge -eq $true -and $targetLanguage -ne "en") {
					$removeItemList = Get-ChildItem -Path $targetPath.Paths.Fullpath -Recurse  -WithParent | Where-Object { $_.Template.FullName -notlike 'Project/CBRE/Pages/Wildcards*' }
					foreach ($removeItem in $removeItemList) {
						Remove-ItemVersion -Path $removeItem.Paths.Fullpath -Language $SourceLanguage -ExcludeLanguage $targetLanguage
					}
					Remove-ItemVersion -Path $headerPath -Language $SourceLanguage -ExcludeLanguage $targetLanguage -Recurse
					Remove-ItemVersion -Path $footerPath -Language $SourceLanguage -ExcludeLanguage $targetLanguage -Recurse
					Remove-ItemVersion -Path $targetGLpath -Language $SourceLanguage -ExcludeLanguage $targetLanguage -Recurse
				}	
			
			
			}
			Catch {
				$ErrorRecord = $Error[0]
				Write-Log -Log Error $ErrorRecord
				Show-Alert "Something went wrong. See SPE logs for more details."
				Close-Window
			}
	
		}
	}
	else {
		Show-Alert "Items already exist. Please check"
	}
		
}

end {
	Write-Verbose "Cmdlet Add-SiteLanguage - End"
}
	
