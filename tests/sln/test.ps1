# Parameter help description
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $pkg,

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $pkgSrc,

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string] $testName
)

git init -q
dotnet add "$testName\$testname.csproj" package $pkg -s $pkgSrc