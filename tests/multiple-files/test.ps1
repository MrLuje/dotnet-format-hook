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
        @("Class1.cs", "Class2.cs") | ForEach-Object { Set-FileModification (Join-Path "$testName" $_) }
        
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

        $r = Start-CommitProcess

        $hookTriggered = Assert-HookTriggered($r)
        $allMatches = Assert-SameFileContent (@("Class1.cs", "Class2.cs") | ForEach-Object { (Join-Path "$testName" $_) })

        return @($allMatches | Where-Object { $_ -eq $false }).Length -eq 0 -and $hookTriggered;

    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

& $main