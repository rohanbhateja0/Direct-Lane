Import-Function Get-SourceFieldReport
Import-Function Test-ItemIsTenant
Import-Function Get-TenantTemplatesRoot

$contextItem = Get-Item .
if(Test-ItemIsTenant $contextItem){
    $ttr = Get-TenantTemplatesRoot $contextItem
    Get-SourceFieldReport $ttr.Paths.Path
}else{
    Get-SourceFieldReport $contextItem.Paths.Path
}
