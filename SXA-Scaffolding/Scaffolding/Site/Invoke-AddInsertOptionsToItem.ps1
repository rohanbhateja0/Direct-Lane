function Invoke-AddInsertOptionsToItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteItem,


        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$ModuleDefinition
    )

    begin {
        Write-Verbose "Cmdlet Invoke-AddInsertOptionsToItem - Begin"
        Import-Function Add-InsertOptionsToItem
    }

    process {
        Write-Verbose "Cmdlet Invoke-AddInsertOptionsToItem - Process"
        [Sitecore.Data.Items.TemplateItem]$baseTemplate = Get-Item -Path master: -ID ($ModuleDefinition.Fields['Template'].Value)
        [Sitecore.Data.ID[]]$arguments = $ModuleDefinition.Fields['Arguments'].Value.Split('|')

        $template = Get-SiteItemBasedOnBaseTemplate $SiteItem $baseTemplate.InnerItem.Template.InnerItem.ID
        if ($template) {
            Write-Verbose "Adding isnert options to item $($template.Paths.Path) : $($arguments)"
            Add-InsertOptionsToItem $template $arguments
        }
    }

    end {
        Write-Verbose "Cmdlet Invoke-AddInsertOptionsToItem - End"
    }
}

function Get-SiteItemBasedOnBaseTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteItem,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Sitecore.Data.ID]$ID
    )

    begin {
        Write-Verbose "Cmdlet Get-SiteItemBasedOnBaseTemplate - Begin"
    }

    process {
        Write-Verbose "Cmdlet Get-SiteItemBasedOnBaseTemplate - Process"
        $SiteItem.Axes.GetDescendants() | ? { ($_.Template.InnerItem.Fields['__Base template'].Value).Contains($ID) -or $_.Template.InnerItem.ID -eq $ID } | Select-Object -First 1 | Wrap-Item
    }

    end {
        Write-Verbose "Cmdlet Get-SiteItemBasedOnBaseTemplate - End"
    }
}