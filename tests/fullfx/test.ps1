<# 
.Description Ensure Format-Hook behave correctly on full .net framework
#>
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
        if ($IsWindows -eq $false) {
            Write-Host "Skipping test (Windows only)" -NoNewline -ForegroundColor Yellow
            return $true
        }

        Set-FileModification (Join-Path "$testName" "Class1.cs")
        
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

        $r = Start-CommitProcess

        $hookTriggered = Assert-HookHasFormatted($r)
        $allMatches = Assert-DifferentFileContent (@(Join-Path "$testName" "Class1.cs"))

        return @($allMatches | Where-Object { $_ -eq $false }).Length -eq 0 -and $hookTriggered;
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

& $main