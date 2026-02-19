function Select-InheritingFrom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0 )]
        $TemplateID,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1 )]
        [Sitecore.Data.Items.Item]$Item
    )
    
    begin {
        Write-Verbose "Cmdlet Select-InheritingFrom - Begin"
    }
    
    process {
        Write-Verbose "Cmdlet Select-InheritingFrom - Process"   
        if ($Item) {
            $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item)
            if ($template -and $template.InheritsFrom($TemplateID)) {
                $Item
            }
        }
    } 
    
    end {
        Write-Verbose "Cmdlet Select-InheritingFrom - End"
    }
}