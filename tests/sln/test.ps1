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
        "       " + (Get-Content "$testName\Class1.cs" -Raw) | Set-Content "$testName\Class1.cs"
        
        git init -q
        git config user.email "a@a.com"
        git config user.name "hey"
        
        dotnet add "$testName\$testname.csproj" package $pkg -s $pkgSrc > $null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install $pkg"
            return $false
        }

        $r = Execute-Command "dotnet" "build" (Get-Location)

        if ($r.ExitCode -eq 0) {
            if ((Test-Path ".git\format-hook.enabled") -eq $false) {
                Write-Error "$testName\.git\format-hook.enabled is missing"
                # Remove-Item -Path .git -Force -Recurse
                return $false
            }
        }
        else {
            Write-Error "Missing .git\format-hook.enabled !"
        }

        git add .
        $r = Execute-Command "git" "commit -m format" (Get-Location)

        if ($r.ExitCode -eq 0) {
            Write-Error "Git commit wasn't prevented by hook :("
        }
        elseif ($r.ExitCode -eq 2) {
            # files formatted
            return $true
        }
        else {
            if ($r.stderr.Contains("Code has been reformatted and changes were staged")) {
                return $true
            }
            Write-Error "Error $($r.ExitCode)"
            Write-Output $r.stderr
            return $false
        }
    }
    catch {
        # Remove-Item -Path .git -Force -Recurse
    }
    return $false
}

Function Execute-Command ($commandPath, $commandArguments, $path) {
    Try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $commandPath
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.WindowStyle = 'Hidden'
        $pinfo.CreateNoWindow = $True
        $pinfo.Arguments = $commandArguments
        $pinfo.WorkingDirectory = $path
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        $p | Add-Member "stdout" $stdout
        $p | Add-Member "stderr" $stderr
    }
    Catch {
    }
    $p
}

& $main