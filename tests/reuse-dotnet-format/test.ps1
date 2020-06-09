# Parameter help description
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $pkg,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $pkgSrc,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $testName
)

$main = {
    try {
        if(-not(Test-Path env:IN_DOCKER)) {
            Write-Host "Skipping test" -NoNewline -ForegroundColor Yellow
            return $true
        }

        Set-FileModification (Join-Path "$testName" "Class1.cs")
        $r = Install-DotnetTool "dotnet-format" "4.0.130203"

        $r = SetGitRepo;
        if ((AssertGitInstalled) -eq $false) {
            return $false
        }
        
        if ((InstallNugetPackage (Join-Path "$testName" "$testname.csproj") $pkg $pkgSrc) -eq $false) {
            return $false
        }

        $r = BuildSolution
        if ((AssertHookInstalled $r) -eq $false) {
            return $false
        }
        if ((Assert-DotnetToolLocallyInstalled "dotnet-format") -eq $true) {
            Write-Error "dotnet-format is locally installed but should have used global version"
            return $false
        }

        $r = Start-CommitProcess

        $hookTriggered = Assert-HookTriggered($r)
        $allMatches = Assert-DifferentFileContent (@(Join-Path "$testName" "Class1.cs"))

        return @($allMatches | Where-Object { $_ -eq $false }).Length -eq 0 -and $hookTriggered;
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    $r = Start-Command "dotnet" "tool uninstall dotnet-format --global"

    return $false
}

& $main