function Get-InvokedSiteAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$TenantTemplates,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$SiteLocation
    )

    begin {
        Write-Verbose "Cmdlet Get-InvokedSiteAction - Begin"
        Import-Function Invoke-ExecuteScript
        Import-Function Get-Action
        Import-Function Get-SettingsItem
        Import-Function Get-SiteDefinitions
        Import-Function Get-ItemByIdSafe
        Import-Function Select-InheritingFrom
    }

    process {
        Write-Verbose "Cmdlet Get-InvokedSiteAction - Process"
        $DefinitionItems = Get-SiteDefinitions "*"
        $ModuleDefinitions = Get-Action $DefinitionItems

        $foundationInsertOptions = $ModuleDefinitions   | ? { $_.TemplateName -eq "EditSiteItem" } | ? { $_.EditType -eq "AddInsertOptions" }
        $addItem = $ModuleDefinitions   | ? { $_.TemplateName -eq "AddItem" }
        $executeScript = $ModuleDefinitions   | ? { $_.TemplateName -eq "ExecuteScript"}
        $editingTheme = $ModuleDefinitions   | ? { $_.TemplateName -eq "EditEditingTheme" } 
        $siteTheme = $ModuleDefinitions   | ? { $_.TemplateName -eq "EditSiteTheme" } 

        $addItem | % {
            $itemName = $_._Name
            Write-Verbose "Processing $($_.ID.ToString())"
            $itemTemplate = (Get-Item -Path master: -ID $_._Template)
            if ($itemTemplate.TemplateName -eq "Branch") {
                $itemTemplate = $itemTemplate.Children[0].Template.Name
            }
            else {
                $itemTemplate = $itemTemplate.Name
            }
            $startLocation = $SiteLocation.Paths.Path
            $query = "$startLocation//*[@@name='$itemName' and @@templatename='$itemTemplate']"
            $createdItems = Get-Item -Path master: -Language "*" -Query $query
            Write-Verbose "Created items count $($createdItems.Count) [$query]"
            if ($createdItems) {
                $_
            }
        }

        $foundationInsertOptions | % {
            Write-Verbose "Processing action: $($_.Paths.Path))"
            [Sitecore.Data.Items.TemplateItem]$baseTemplate = (Get-Item -Path master: -ID ($_.Fields['Template'].Value)).Template
            [Sitecore.Data.Items.TemplateItem[]]$arguments = $_.Fields['Arguments'].Value.Split('|') | % {Get-Item -Path master: -ID $_}

            $template = Get-ChildItem -Path $SiteLocation.Paths.Path -Recurse -WithParent | Select-InheritingFrom ($baseTemplate.ID) | Wrap-Item
            if ($template.Length -gt 1) { 
                $template = $template | Select-Object -First 1 
                Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
            }            
            if ($template) {
                Write-Verbose "Edited template was: $($template.Paths.Path)"
                $standardValuesHolder = $template
                if ($standardValuesHolder) {
                    [Sitecore.Data.ID[]]$baseTemplates = $standardValuesHolder."__Masters".Split('|') | ? { [guid]::TryParse($_, [ref][guid]::Empty) }
                    if ($baseTemplates) {
                        $x = $arguments | % {
                            Write-Verbose "Added Insert Option $($_.ID)"
                            Write-Verbose "$baseTemplates"
                            if ($baseTemplates.Contains($_.ID)) {
                                $true
                            }
                        }

                        if ($x.length -gt 0) {
                            $_
                        }
                    }
                }
            }
        }

        $executeScript | % {
            $ScriptFieldName = 'ValidationScript'
            $validationScript = $_.Fields[$ScriptFieldName]
            if ($_.Fields[$ScriptFieldName].Value -ne "") {
                $result = Invoke-ExecuteScript $_ $SiteLocation $TenantTemplates $ScriptFieldName
                if ($result) {
                    $_
                }
            }
        }
        
        $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
        $themingContext = $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Theming.IThemingContext])
        
        $settingsItem = Get-SettingsItem $SiteLocation
        $editing = Get-ItemByIdSafe $settingsItem.EditingTheme
        if ($editing) {
            $list = New-Object System.Collections.Generic.List``1[Sitecore.Data.ID]
            $installedEditingThemeFeatures = $themingContext.GetThemesWithBaseThemes($editing, $list, "{E0367CD6-E333-4625-9993-BAA4F1C0C92B}") | % { $_.ID.ToString() }
            
            $editingTheme | ? {
                $installedEditingThemeFeatures.Contains($_.Arguments.ToString())
            }
        }

        $defaultDevice = Get-Item . -Id "{FE5D7FDF-89C0-4D99-9AA3-B5FBD009C9F3}"
        $themeItem = $themingContext.GetThemeItem($SiteLocation, $defaultDevice)
        if ($themeItem) {
            $list = New-Object System.Collections.Generic.List``1[Sitecore.Data.ID]
            $installedEditingThemeFeatures = $themingContext.GetThemesWithBaseThemes($themeItem, $list, "{384C2D3C-3E34-4493-9CB2-ADE68CAF0DA2}") | % { $_.ID.ToString() }
    
            $siteTheme | ? {
                $installedEditingThemeFeatures.Contains($_.Arguments.ToString())
            }
        }        
    }
    end {
        Write-Verbose "Cmdlet Get-InvokedSiteAction - End"
    }
}