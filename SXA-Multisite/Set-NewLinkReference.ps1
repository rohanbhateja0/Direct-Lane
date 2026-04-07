function Set-CBRENewLinkReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [Item]$SourceSite,

        [Parameter(Mandatory = $true, Position = 1)]
        [Item]$DestinationSite,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$SourcePath,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$DestinationPath
    )

    begin {
        Write-Host "Cmdlet Set-CBRENewLinkReference - Begin"
        $IdRegex = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|((?<=link.aspx\?_id=)[0-9a-fA-F]{32})"
    }

    process {
        Write-Host "Cmdlet Set-CBRENewLinkReference - Process"
        Write-Host "  - Source site: $($SourceSite.Paths.Path)"
        Write-Host "  - Destination site: $($DestinationSite.Paths.Path)"

        if ($SourcePath -eq "") {
            $SourcePath = $SourceSite.Paths.Path
        }

        if ($DestinationPath -eq "") {
            $DestinationPath = $DestinationSite.Paths.Path
        }
        
        Write-Host "  - Source path: $SourcePath"
        Write-Host "  - Destination path: $DestinationPath"
        
        $tmp_sourcePath = If ($SourcePath.EndsWith("/") ) { $SourcePath } Else { $SourcePath + "/" }
        $tmp_destinationPath = If ($DestinationPath.EndsWith("/") ) { $DestinationPath } Else { $DestinationPath + "/" }

        Write-Host "  - Scanning items for link references..."
        $itemCount = 0
        $referenceCount = 0
        $processed = New-Object System.Collections.Specialized.OrderedDictionary
        Get-ChildItem -Path $DestinationSite.Paths.Path -Recurse -Language * -WithParent |  ForEach-Object {
            $itemCount++
            $currentItem = $_
            $_.Fields.ReadAll()

            $fieldsWithIds = $_.Fields | ? { [regex]::IsMatch($_.Value, $IdRegex) }

            foreach ($field in $fieldsWithIds) {
                $IDs = [regex]::Matches($field.Value, $IdRegex)

                foreach ($idMatch in $IDs) {
                    $id = New-Object -TypeName "Sitecore.Data.ID" -ArgumentList $idMatch
                    $linkedItem = $currentItem.Database.GetItem($id)
                    if ($linkedItem -ne $null) {
                        if ($linkedItem.Paths.Path.StartsWith($SourcePath) -eq $true) {
                            $linkedItemPath = $linkedItem.Paths.Path + "/"
                            $desiredItemPath = $linkedItemPath.Replace($tmp_sourcePath, $tmp_destinationPath)
                            $key = "$($currentItem.ID)$($id)$($desiredItemPath)$($field.Name)[$($currentItem.Language.Name)]"
                            if ($processed.Contains($key)) {
                                continue
                            }
                            $desiredItem = $currentItem.Database.GetItem($desiredItemPath)

                            if ($desiredItem -ne $null) {
                                $referenceCount++
                                Write-Host "    - Replacing ID from: $($id) to: $($desiredItem.ID) for $($field.Name) field [$($currentItem.Language.Name)] on item: $($currentItem.Paths.Path)"
                                $fieldValue = $currentItem.Fields[$field.Name].Value;
                                if ($idMatch.Value.Contains("-")) {
                                    $guidFormat = "D"
                                }
                                else {
                                    $guidFormat = "N"
                                }
                                $oldValue = $id.Guid.ToString($guidFormat).ToUpper()
                                $newValue = $desiredItem.ID.Guid.ToString($guidFormat).ToUpper()
                                $updatedFieldValue = [System.Text.RegularExpressions.Regex]::Replace($fieldValue, $oldValue, $newValue, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                                $currentItem.Editing.BeginEdit() > $null
                                $currentItem.Fields[$field.Name].Value = $updatedFieldValue
                                $currentItem.Editing.EndEdit() > $null
                                $processed.Add($key, 0)
                            }
                            else {
                                Write-Host "    - Warning: Could not resolve desired item for path: $($desiredItemPath)" -ForegroundColor Yellow
                            }
                        }
                    }
                }
            }

            $fieldsWithPaths = $_.Fields | ? { [regex]::IsMatch($_.Value, $SourcePath) }
            foreach ($field in $fieldsWithPaths) {
                $referenceCount++
                Write-Host "    - Replacing path from: '$SourcePath' to: '$DestinationPath' for $($field.Name) field on item: $($currentItem.Paths.Path)"
                $currentItem."$($field.Name)" = $currentItem."$($field.Name)".Replace($SourcePath, $DestinationPath)
            }            
        }
        Write-Host "  - Processed $itemCount item(s), updated $referenceCount reference(s)" -ForegroundColor Green
    }

    end {
        Write-Host "Cmdlet Set-CBRENewLinkReference - End"
    }
}