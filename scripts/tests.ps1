$pkgs = Get-ChildItem "..\src\format-hook" -Filter "*.nupkg" -Recurse
if ($pkgs.Length -eq 0) {
    dotnet pack "..\src\format-hook"
    $pkgs = Get-ChildItem "..\src\format-hook" -Filter "*.nupkg" -Recurse

    if ($pkgs.Length -eq 0) {
        Write-Error "Can't find nupkg file under 'src\format-hook'"
    }

}
$pkg = $pkgs[0].Name
$pkgFolder = $pkgs[0].Directory.FullName
$currentPath = Get-Location

Get-ChildItem "..\tests" |
ForEach-Object {
    $testName = $_.Name
    $testFullpath = $_.FullName

    Set-Location -Path $testFullpath

    Write-Host "** Testing '$testName' " -NoNewline
    $success = Invoke-Command { & "$testFullpath\test.ps1" -pkg "format-hook" -pkgSrc $pkgFolder -testName $testName }
    Set-Location -Path $currentPath
    git restore --source=HEAD --staged --worktree -- "$testFullpath\$testName"

    if($success -eq $true) {
        Write-Host -ForegroundColor "GREEN" " OK"
    }
    else {
        Write-Error "Test '$testName' failed"
    }
}