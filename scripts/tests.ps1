$out = (Join-Path ".." "out")
if ((Test-Path $out)) {
    Remove-Item -Path $out -Force -Recurse
    if ($? -eq $false) {
        Write-Error "Can't clear ./out folder"
        Return
    }
}

New-Item $out -ItemType Directory > $null
$nugetFormatHookPath = $(if ($null -ne $env:USERPROFILE) { ([IO.Path]::Combine("$env:USERPROFILE", ".nuget", "packages", "format-hook")) } else { ([IO.Path]::Combine("$env:HOME", ".nuget", "packages", "format-hook")) })

if ($env:VERBOSE -eq "true") {
    Write-Host "Removing nuget at $nugetFormatHookPath"
}
Remove-Item -Path $nugetFormatHookPath -Recurse -Force -ErrorAction SilentlyContinue

dotnet pack ([IO.Path]::Combine("..", "src", "format-hook")) -o $out
$pkgs = Get-ChildItem $out -Filter "*.nupkg" -Recurse

if ($pkgs.Length -eq 0) {
    Write-Error "Can't find nupkg file under 'out\'"
    Return
}

$pkgFolder = $pkgs[0].Directory.FullName
$currentPath = Get-Location
Write-Host "Using package $($pkgs[0].FullName)"

Copy-Item -Path (Join-Path ".." "tests") -Destination "..\out" -Recurse

Get-ChildItem ([IO.Path]::Combine("..", "out", "tests")) -Directory |
ForEach-Object {
    $testName = $_.Name
    $testFullpath = $_.FullName

    Set-Location -Path $testFullpath

    Write-Host "** Testing '$testName' " -NoNewline
    $result = Invoke-Command { & (Join-Path -Path $testFullpath -ChildPath "test.ps1") -pkg "format-hook" -pkgSrc $pkgFolder -testName $testName }
    Set-Location -Path $currentPath

    $success = if ($result.Length -gt 1) { $result | Select-Object -Last 1 } else { $result }
    switch ($success) {
        { $_ -eq $true } { 
            Write-Host -ForegroundColor "GREEN" " OK";
            exit 0;
        }
        { $_ -eq $false } { 
            Write-Host $result;
            Write-Error "Test '$testName' failed"; 
            break;
        }
        Default { 
            Write-Host $result;
            Write-Error "Test '$testName' failed";
        }
    }
    exit 1;
}