function IncludeRoot($package, $rootItem, $name, $installMode) {
    $source = New-ItemSource -Root ($rootItem.Paths.Path) -Database ($rootItem.Database) -Name $name -InstallMode $installMode
    $package.Sources.Add($source) > $null
    $package
}

function IncludeParentsUntilID ($package, $startItem, $stopID, $installMode, $mergeMode) {
    $tempItem = $startItem.Parent        
    while ($tempItem.ID -ne $stopID) {
        $source = $tempItem | New-ExplicitItemSource -Name $tempItem.ID -InstallMode $installMode -MergeMode $mergeMode        
        $package.Sources.Add($source) > $null
        $tempItem = $tempItem.Parent
    }
    $package
}

function Get-TenantPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$Tenant
    )

    begin {
        Write-Verbose "Cmdlet Get-TenantPackage - Begin"
        Import-Function Get-ItemByIdSafe
    }

    process {
        Write-Verbose "Cmdlet Get-TenantPackage - Process"
        $tenantItem = $Tenant

        $timestamp = Get-Date -Format "yyyyMMdd.HHss"
        $item = Get-Item .
        $path = $item.ProviderPath
        $packageName = "$timestamp.$($item.Name)"
        $version = $item.Version
        $Author = [Sitecore.Context]::User.Profile.FullName;
        $Publisher = [Sitecore.SecurityModel.License.License]::Licensee

        $result = Read-Variable -Parameters `
        @{ Name = "packageName"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPackageName)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPackageMetadata))}, `
        @{ Name = "Author"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogAuthor)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPackageMetadata))}, `
        @{ Name = "Publisher"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPublisher)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPackageMetadata))}, `
        @{ Name = "Version"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogVersion)); Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPackageMetadata))}, `
        @{ Name = "Readme"; Title = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogReadme)); Lines = 10; Tab = ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogPackageMetadata))} `
            -Description ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogDescription)) `
            -Title ([Sitecore.Globalization.Translate]::Text([Sitecore.XA.Foundation.Multisite.Texts]::ExportTenantDialogTitle)) -Width 600 -Height 700 -ShowHints
        

        if ($result -ne "ok") {
            Close-Window
            Exit
        }

        # Initialize package
        $package = New-Package $packageName
        $package.Sources.Clear();
        $package.Metadata.Author = $Author;
        $package.Metadata.Publisher = $Publisher;
        $package.Metadata.Version = $Version;
        $package.Metadata.Readme = $Readme;

        $installMode = "Merge"
        $mergeMode = "Merge"

        # Get package source roots
        $tenantMediaLibrary = Get-ItemByIdSafe $tenantItem.MediaLibrary
        $formsFolder = Get-ItemByIdSafe $tenantItem.Fields["FormsFolderLocation"].Value
        $tenantThemes = Get-ItemByIdSafe $tenantItem.Themes
        $tenantTemplates = Get-ItemByIdSafe $tenantItem.Templates

        # Add package root sources
        if ($tenantTemplates) {
            $package = IncludeRoot $package $tenantTemplates        "Templates"     $installMode
        }
        if ($tenantMediaLibrary) {
            $package = IncludeRoot $package $tenantMediaLibrary     "Media Library" $installMode
        }
        if ($formsFolder) {
            $package = IncludeRoot $package $formsFolder            "Forms"         $installMode
        }
        if ($tenantThemes) {
            $package = IncludeRoot $package $tenantThemes           "Themes"        $installMode
        }
        if ($tenantItem) {
            $package = IncludeRoot $package $tenantItem             "Content"       $installMode
        }

        # Add package explicit sources
        $tenantFolderItem = $tenantItem.Parent
        $tenantFolderTemplateId = [Sitecore.XA.Foundation.Multisite.Templates+_BaseTenantFolder]::ID.ToString()
        while ([Sitecore.Data.Managers.TemplateManager]::GetTemplate($tenantFolderItem).InheritsFrom($tenantFolderTemplateId)) {
            $source = $tenantFolderItem | New-ExplicitItemSource -Name $tenantFolderItem.ID -InstallMode $installMode -MergeMode $mergeMode
            $package.Sources.Add($source)
            $tenantFolderItem = $tenantFolderItem.Parent
        }

        if ($tenantTemplates) {
            $package = IncludeParentsUntilID $package $tenantTemplates      "{825B30B4-B40B-422E-9920-23A1B6BDA89C}"    $installMode $mergeMode
        }
        if ($tenantThemes) {
            $package = IncludeParentsUntilID $package $tenantThemes         "{3CE9A090-FB9B-42BE-B593-F39BFCB1DE2B}"    $installMode $mergeMode
        }
        if ($tenantMediaLibrary) {
            $package = IncludeParentsUntilID $package $tenantMediaLibrary   "{90AE357F-6171-4EA9-808C-5600B678F726}"    $installMode $mergeMode
        }
        if ($formsFolder) {
            $package = IncludeParentsUntilID $package $formsFolder          "{B701850A-CB8A-4943-B2BC-DDDB1238C103}"    $installMode $mergeMode
        }

        # Export package & project
        $packageFileName = "$packageName-$version.zip";
        Export-Package -Project $package -Path "$($SitecorePackageFolder)\$packageFileName" -Zip

        Download-File "$SitecorePackageFolder\$packageFileName"
        Remove-Item "$SitecorePackageFolder\$packageFileName"
        Close-Window
    }

    end {
        Write-Verbose "Cmdlet Get-TenantPackage - End"
    }
}