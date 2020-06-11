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
        $files = @("Class1.cs", "Class2.cs") 
        $files | ForEach-Object { Set-FileModification (Join-Path "$testName" $_) }
        
        $r = SetGitRepo;
        if ((Assert-GitInstalled) -eq $false) {
            return $false
        }
        
        if ((Install-NugetPackage (Join-Path "$testName" "$testname.csproj") $pkg $pkgSrc) -eq $false) {
            return $false
        }

        $r = Build-Solution
        if ((Assert-HookInstalled $r) -eq $false) {
            return $false
        }

        # only stage Class1.cs
        git add (Join-Path "$testName" "Class1.cs") 
        $r = Start-CommitProcess -gitAddAll $false

        $hookTriggered = Assert-HookHasFormatted($r)

        $allMatchesSame = Assert-SameFileContent ((Join-Path "$testName" "Class2.cs"))
        $allMatchesDifferent = Assert-DifferentFileContent ((Join-Path "$testName" "Class1.cs"))

        return @($allMatchesSame | Where-Object { $_ -eq $true }).Length -eq 1
        -and @($allMatchesDifferent | Where-Object { $_ -eq $true }).Length -eq 1 
        -and $hookTriggered;

    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

& $main