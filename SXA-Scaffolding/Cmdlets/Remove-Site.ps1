function Remove-Site {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$SiteItem,
        [switch]$Force
    )

    begin {
        Write-Verbose "Cmdlet Remove-Site - Begin"
        Import-Function Get-ItemByIdSafe
        Import-Function Get-Modules
        Import-Function Invoke-PreDeleteStep
        Import-Function Invoke-PostDeleteStep
        Import-Function Test-HasPreDeleteStep
        Import-Function Test-HasPostDeleteStep
        Import-Function Invoke-PreDeleteValidationStep
    }

    process {
        Write-Verbose "Cmdlet Remove-Site - Process"
        
        $siteModules = Get-Modules $SiteItem | % { $_.InnerItem } 
        if ($Force) {
            $canRemove = $true
        }
        else {
            if($siteModules){
                $canRemove = Invoke-PreDeleteValidationStep $siteModules $SiteItem
            }else{
                $canRemove = $true
            }
        }        
        if ($canRemove -eq $true) {
            if($siteModules){
                $preSetupStepModules = $siteModules | ? { Test-HasPreDeleteStep $_ }
                $postSetupStepModules = $siteModules | ? { Test-HasPostDeleteStep $_ }
            }
            if ($preSetupStepModules) {
                Invoke-PreDeleteStep $preSetupStepModules $SiteItem
            }
        
            $SiteMediaLibrary = Get-ItemByIdSafe $SiteItem.SiteMediaLibrary
            $ThemesFolder = Get-ItemByIdSafe $SiteItem.ThemesFolder
            $FormsFolderLocation = Get-ItemByIdSafe $SiteItem.FormsFolderLocation
        
            if ($SiteMediaLibrary) {
                $SiteMediaLibrary.Recycle() > $null
            }
            if ($ThemesFolder) {
                $ThemesFolder.Recycle() > $null
            }
            if ($FormsFolderLocation) {
                $FormsFolderLocation.Recycle() > $null
            }
        
            $SiteItem.Children | ForEach-Object {
                Write-Progress -Status "Removing '$($SiteItem.Name)' site" -Activity "Removing '$($_.Name)' item" -Completed
                $_.Recycle() > $null
            }
        
            Write-Progress -Status "Removing '$($SiteItem.Name)' site" -Activity "Removing site item" -Completed
            $SiteItem.Recycle() > $null
            if ($postSetupStepModules) {
                Invoke-PostDeleteStep $postSetupStepModules $SiteItem
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Remove-Site - End"
    }
}