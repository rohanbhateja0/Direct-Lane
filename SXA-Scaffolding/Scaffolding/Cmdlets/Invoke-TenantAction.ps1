function Invoke-TenantAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0 )]
        [Item]$tenant,

        [Parameter(Mandatory = $true, Position = 1 )]
        [Item]$ActionItem,
		
		[Parameter(Mandatory=$false, Position = 2 )]
		[string]$Language="en"	        
    )

    begin {
        Write-Verbose "Cmdlet Invoke-TenantAction - Begin"
        Import-Function Invoke-AddInsertOptionsToTemplate
        Import-Function Invoke-AddBaseTemplate
        Import-Function Invoke-AddInsertOptionAdvanced
        Import-Function Invoke-ExecuteScript
        Import-Function Invoke-AddItem
        Import-Function Set-TenantTemplate
        Import-Function Invoke-ExecuteScript
        Import-Function Get-TenantTemplate
    }

    process {
        Write-Verbose "Cmdlet Invoke-TenantAction - Process"
        $tenantTemplatesRootID = $tenant.Fields['Templates'].Value
        $tenantTemplatesRoot = Get-Item -Path master: -ID $tenantTemplatesRootID
        $tenantTemplates = Get-TenantTemplate $tenantTemplatesRoot

        Write-Verbose "Invoking Tenant Action: $($ActionItem.Paths.Path)"
        switch ($ActionItem.TemplateName) {
            "EditTenantTemplate" {
                if ($ActionItem.EditType -eq "AddBaseTemplate") {
                    Invoke-AddBaseTemplate $ActionItem $tenantTemplates
                }
                if ($ActionItem.EditType -eq "AddInsertOptions") {
                    Invoke-AddInsertOptionsToTemplate $ActionItem $tenantTemplates
                }
                if ($ActionItem.EditType -eq "AddTenantTemplatesToInsertOptions") {
                    Invoke-AddInsertOptionAdvanced $ActionItem $tenantTemplates
                }
                $tenantTemplates = Get-TenantTemplate $tenantTemplatesRoot
                Set-TenantTemplate $tenant $tenantTemplates
            }
            "AddItem" {
                Invoke-AddItem $tenant $ActionItem $Language
            }
            "ExecuteScript" {
                Invoke-ExecuteScript $ActionItem  $tenant $tenantTemplates
            }
            Default {}
        }
    }

    end {
        Write-Verbose "Cmdlet Invoke-TenantAction - End"
    }
}