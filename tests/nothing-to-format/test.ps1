<#
    Ensure files are not modified if there is nothing to reformat
#>
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
        New-FileBackup (Join-Path "$testName" "Class1.cs")

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

        $hookNotTriggered = Assert-HookHasNotFormatted($r)
        $allMatches = Assert-SameFileContent (@(Join-Path "$testName" "Class1.cs"))

        return @($allMatches | Where-Object { $_ -eq $false }).Length -eq 0 -and $hookNotTriggered;
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

& $main