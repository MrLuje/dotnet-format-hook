$out = (Join-Path ".." "out")
if ((Test-Path $out)) {
    Remove-Item -Path $out -Force -Recurse
    if ($? -eq $false) {
        Write-Error "Can't clear ./out folder"
        Return
    }
}

New-Item $out -ItemType Directory > $null
Remove-Item -Path ([IO.Path]::Combine("$env:USERPROFILE", ".nuget", "packages", "format-hook")) -Recurse -ErrorAction SilentlyContinue

dotnet pack ([IO.Path]::Combine("..", "src", "format-hook")) -o $out
$pkgs = Get-ChildItem $out -Filter "*.nupkg" -Recurse

if ($pkgs.Length -eq 0) {
    Write-Error "Can't find nupkg file under 'out\'"
    Return
}

$pkg = $pkgs[0].Name
$pkgFolder = $pkgs[0].Directory.FullName
$currentPath = Get-Location
Write-Host "Using package $pkg"

Copy-Item -Path (Join-Path ".." "tests") -Destination "..\out" -Recurse

Get-ChildItem ([IO.Path]::Combine("..", "out", "tests")) |
ForEach-Object {
    $testName = $_.Name
    $testFullpath = $_.FullName

    Set-Location -Path $testFullpath

    Write-Host "** Testing '$testName' " -NoNewline
    $success = Invoke-Command { & (Join-Path -Path $testFullpath -ChildPath "test.ps1") -pkg "format-hook" -pkgSrc $pkgFolder -testName $testName }
    Set-Location -Path $currentPath

    switch ($success) {
        { $_ -eq $true } { 
            Write-Host -ForegroundColor "GREEN" " OK"; break 
            exit 0;
        }
        { $_ -eq $false } { 
            Write-Error "Test '$testName' failed"; break 
        }
        Default { 
            Write-Error "Test '$testName' failed"
            Write-Host $success
        }
    }
    exit 1;
}