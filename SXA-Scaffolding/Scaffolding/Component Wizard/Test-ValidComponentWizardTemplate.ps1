function Test-ValidComponentWizardTemplate {
    param (
        [Parameter(Mandatory = $false, Position = 0 )]
        [Item]$Item,
        [Parameter(Mandatory = $false, Position = 1 )]
        [Sitecore.Data.ID]$BaseTemplate
    )

    begin {
        Write-Verbose "Cmdlet Test-ValidComponentWizardTemplate - Begin"
    }

    process {
        $template = [Sitecore.Data.Managers.TemplateManager]::GetTemplate($Item.ID, $Item.Database)
        if ($template -eq $null) {
            [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardErrorNotATemplate)
        }
        else {
            if ($template.InheritsFrom($BaseTemplate) -eq $false) {                
                [Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Scaffolding.Texts]::ComponentWizardErrorTemplateInheritance) -f $BaseTemplate.ToString()
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Test-ValidComponentWizardTemplate - End"
    }
}