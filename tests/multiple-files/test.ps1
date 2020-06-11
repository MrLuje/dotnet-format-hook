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

        $r = Start-CommitProcess

        $hookTriggered = Assert-HookHasFormatted($r)
        $allMatches = Assert-DifferentFileContent ($files | ForEach-Object { (Join-Path "$testName" $_) })

        return @($allMatches | Where-Object { $_ -eq $false }).Length -eq 0 -and $hookTriggered;

    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

& $main