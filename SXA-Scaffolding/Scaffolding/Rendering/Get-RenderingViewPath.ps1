function GetFullViewPath($format, $view, $controller) {
    $viewPath = $format -f $view, $controller
    $fullName = Join-Path $AppPath $viewPath
    $fullName = $fullName.Replace("\~", "")    
    $fullName
}

function Get-RenderingViewPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0 )]
        [Item]$RenderingItem
    )

    begin {
        Write-Verbose "Cmdlet Get-RenderingViewPath - Begin"
    }

    process {
        $RenderingItem.Fields.ReadAll()
        if ($RenderingItem.Fields.Name.Contains("RenderingViewPath")) {
            Write-Verbose "Cmdlet Get-RenderingViewPath - Process"
            $mvcRendering = New-Object "Sitecore.Mvc.Presentation.Rendering"
            $mvcRendering.RenderingItem = $RenderingItem
            $wrapper = New-Object "Sitecore.XA.Foundation.Mvc.Wrappers.Rendering" -ArgumentList $mvcRendering
            $instance = [Sitecore.DependencyInjection.ServiceLocator]::ServiceProvider
            $viewPathCandidate = $instance.GetType().GetMethod('GetService').Invoke($instance, [Sitecore.XA.Foundation.Mvc.Services.IRenderingViewResolver]).GetViewPath($wrapper)
            if ($viewPathCandidate.StartsWith("~")) {
                $viewPathCandidate
            }
            else {
                if ($RenderingItem.Fields.Name.Contains("Controller")) {
                    $typeInfo = [Sitecore.Reflection.ReflectionUtil]::GetTypeInfo($RenderingItem.Controller)
                    if ($null -eq $typeInfo) {
                        return [string]::Empty
                    }
                    $controller = $typeInfo.Name.Replace("Controller", "")
                    $view = $controller
                    $formats = [System.Web.Mvc.ViewEngines]::Engines.ViewLocationFormats
                    $formats += (New-Object System.Web.Mvc.RazorViewEngine).ViewLocationFormats
                    $formats = $formats | Select-Object -Unique 
                    $r = $formats | ? { Test-Path (GetFullViewPath $_ $view $controller) } | Select-Object -First 1 | % { $_ -f $view, $controller }
                    if ($r -eq $null) {
                        $formats | ? { Test-Path (GetFullViewPath $_ $viewPathCandidate $controller) } | Select-Object -First 1 | % { $_ -f $viewPathCandidate, $controller }
                    }
                    else {
                        $r
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "Cmdlet Get-RenderingViewPath - End"
    }
}