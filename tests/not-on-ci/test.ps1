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
        $env:CI="true";

        Set-FileModification (Join-Path "$testName" "Class1.cs")
        
        $r = SetGitRepo;
        if ((AssertGitInstalled) -eq $false) {
            return $false
        }
        
        if ((InstallNugetPackage (Join-Path "$testName" "$testname.csproj") $pkg $pkgSrc) -eq $false) {
            return $false
        }

        $r = BuildSolution
        if ((AssertHookNotInstalled $r) -eq $false) {
            return $false
        }

        $r = Start-CommitProcess

        $hookNotTriggered = Assert-HookNotTriggered($r)
        $allMatches = Assert-DifferentFileContent (@(Join-Path "$testName" "Class1.cs"))

        return @($allMatches | Where-Object { $_ -eq $false }).Length -eq 0 -and $hookNotTriggered;
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

& $main