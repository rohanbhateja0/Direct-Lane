function Get-InvokedTenantAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item[]]$TenantTemplates,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$SiteLocation    
    )

    begin {
        Write-Verbose "Cmdlet Get-InvokedTenantAction - Begin"
        Import-Function Get-ProjectTemplateBasedOnBaseTemplate
        Import-Function Invoke-ExecuteScript
        Import-Function Get-TenantItem
        Import-Function Get-Action
        if((Get-Command Get-TenantDefinition -ErrorAction SilentlyContinue) -eq $null){
            Import-Function Get-TenantDefinition
        }
    }

    process {
        Write-Verbose "Cmdlet Get-InvokedTenantAction - Process"
        $DefinitionItems = Get-TenantDefinition "*"
        $ModuleDefinitions = Get-Action $DefinitionItems

        $foundationAddBaseTemplate = $ModuleDefinitions   | ? { $_.TemplateName -eq "EditTenantTemplate" } | ? { $_.EditType -eq "AddBaseTemplate" }
        $foundationInsertOptions = $ModuleDefinitions   | ? { $_.TemplateName -eq "EditTenantTemplate" } | ? { $_.EditType -eq "AddInsertOptions" }
        $addItem = $ModuleDefinitions   | ? { $_.TemplateName -eq "AddItem" }
        $executeScript = $ModuleDefinitions   | ? { $_.TemplateName -eq "ExecuteScript"}


        $addItem | % {
            $itemName = $_._Name
            Write-Verbose "Processing $($_.ID.ToString())"
            $itemTemplate = (Get-Item -Path master: -ID $_._Template).Name
            $startLocation = (Get-TenantItem $SiteLocation).Paths.Path
            $query = "$startLocation//*[@@name='$itemName' and @@templatename='$itemTemplate']"
            $createdItems = Get-Item -Path master: -Language "*" -Query $query
            Write-Verbose "Created items count $($createdItems.Count) [$query]"
            if ($createdItems) {
                $_
            }
        }

        $foundationInsertOptions | % {
            Write-Verbose "Processing action: $($_.Paths.Path))"
            [Sitecore.Data.Items.TemplateItem]$baseTemplate = Get-Item -Path master: -ID ($_.Fields['Template'].Value)
            [Sitecore.Data.Items.TemplateItem[]]$arguments = $_.Fields['Arguments'].Value.Split('|') | % {Get-Item -Path master: -ID $_}

            $template = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $baseTemplate.InnerItem.Template.InnerItem.ID | Wrap-Item
            if($template.Length -gt 1){ 
                $template = $template | Sort-Object -Property @{Expression={$_."__Base template".Length }} -Descending | Select-Object -First 1 
                Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
            }
            if ($template) {
                Write-Verbose "Edited template was: $($template.Paths.Path)"
                $standardValuesHolder = Get-Item -Path master: -ID $template.'___Standard values'
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

        $foundationAddBaseTemplate | % {
            Write-Verbose "Processing action: $($_.Paths.Path))"
            [Sitecore.Data.Items.TemplateItem]$baseTemplate = Get-Item -Path master: -ID ($_.Fields['Template'].Value)
            [Sitecore.Data.Items.TemplateItem[]]$arguments = $_.Fields['Arguments'].Value.Split('|') | % {Get-Item -Path master: -ID $_}

            $template = Get-ProjectTemplateBasedOnBaseTemplate $TenantTemplates $baseTemplate.InnerItem.Template.InnerItem.ID | Wrap-Item
            if($template.Length -gt 1){ 
                $template = $template | Sort-Object -Property @{Expression={$_."__Base template".Length }} -Descending | Select-Object -First 1 
                Write-Verbose "Found more than one matching template. First one will be selected ($($template.ID))"
            }            
            if ($template) {
                Write-Verbose "Edited template was: $($template.Paths.Path)"
                [Sitecore.Data.ID[]]$baseTemplates = $template."__Base Template".Split('|')
                $x = $arguments | % {
                    Write-Verbose "Added Base template $($_.ID)"
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
    }
    end {
        Write-Verbose "Cmdlet Get-InvokedTenantAction - End"
    }
}