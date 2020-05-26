# Parameter help description
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $pkg,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $pkgSrc,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $testName
)
try {
    # git init -q
    "       " + (Get-Content "$testName\Class1.cs" -Raw) | Set-Content "$testName\Class1.cs"
    
    # git add "$testName"
    
    dotnet add "$testName\$testname.csproj" package $pkg -s $pkgSrc > $null
    dotnet build > $null
    $success = Test-Path ".git\format-hook.enabled"
    # git reset --hard HEAD
    # Remove-Item -Path .git -Force -Recurse

    return $success
}
catch {
    # git reset
    # Remove-Item -Path .git -Force -Recurse
    return $false
}
