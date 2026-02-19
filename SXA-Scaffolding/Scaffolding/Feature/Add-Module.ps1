function Add-Module {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Sitecore.XA.Foundation.Scaffolding.Models.NewModuleModel]$Model
    )

    begin {
        Write-Verbose "Cmdlet Add-Module - Begin"
        Import-Function Add-FolderStructure
    }

    process {
        Write-Verbose "Cmdlet Add-Module - Process"

        if($Model.Roots.Count -gt 0){
            $Model.Roots | % { 
                $root = $_
                $expectedPath = $root.Paths.Path + $Model.Tail + "/" + $Model.Name
                if (-not (Test-Path $expectedPath)) {
                    Add-FolderStructure $expectedPath $root.Template.FullName > $null
                }
                
                if($root.Paths.Path.StartsWith("/sitecore/system/Settings/")){
                    $settingsItem = Get-Item -Path $expectedPath
                    $Model.SetupItemTemplatesIds | % {
                        [Sitecore.Data.Items.TemplateItem]$templateItem = (Get-Item -Path . -ID $_ )
                        $setupItem = New-Item -ItemType $templateItem.FullName -Path $settingsItem.Paths.Path -Name "$($Model.Name) $($templateItem.'DisplayName')"  | Wrap-Item
                        $setupItem.__Name = $Model.Name
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Add-Module - End"
    }
}