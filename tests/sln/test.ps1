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
        "       " + (Get-Content (Join-Path "$testName" "Class1.cs") -Raw) | Set-Content (Join-Path "$testName" "Class1.cs")
        
        if ($env:VERBOSE -eq "true") {
            Execute-Command "git" "init"
        }
        else {
            Execute-Command "git" "init -q"
        }
        Execute-Command "git" "config user.email 'a@a.com'"
        Execute-Command "git" "config user.name 'hey'"

        if ((Test-Path ".git") -eq $false) {
            Write-Error "Git repo in test wasn't initialized"
            return $false
        }
        
        $pathToCsProj = Join-Path "$testName" "$testname.csproj"
        $r = Execute-Command "dotnet" "add $pathToCsProj package $pkg -s $pkgSrc"
        if ($r.ExitCode -ne 0) {
            Write-Error "Failed to install $pkg"
            # Write-Output $r.stderr
            # Write-Output $r.stdout
            return $false
        }

        if ($env:VERBOSE -eq "true") {
            Write-Output "Executing dotnet build"
        }
        
        $r = Execute-Command "dotnet" "build /flp:v=diag"

        if ($r.ExitCode -eq 0) {
            if ((Test-Path (Join-Path ".git" "format-hook.enabled")) -eq $false) {
                Write-Error "$testName\.git\format-hook.enabled is missing"
                Write-Output $r.stdout
                return $false
            }
        }
        else {
            Write-Error "dotnet build failed"
            # Write-Output $r.stdout
            return $false
        }

        git add .
        $r = Execute-Command "git" "commit -m format"

        if ($r.ExitCode -eq 0) {
            Write-Error "Git commit wasn't prevented by hook :("
            Write-Information "Re-running hooks in debug"
            # bash -x "hooks/pre-commit"
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
        $ErrorMessage = $_.Exception.Message
        Write-Output $ErrorMessage
    }
    return $false
}

Function Execute-Command ($commandPath, $commandArguments, $path = (Get-Location)) {
    Try {
        if ($env:VERBOSE -eq "true") {
            Write-Host "Calling " -NoNewline
            Write-Host "$commandPath $commandArguments" -NoNewline -ForegroundColor "GREEN"
            Write-Host " from $path... " -NoNewline
        }

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

    if ($env:VERBOSE -eq "true") {
        if ($p.ExitCode -eq 0) {
            Write-Host "done"
            if ($p.stdout -ne "") {
                Write-Host $p.stdout
            }
            if ($p.stderr -ne "") {
                Write-Host $p.stderr
            }
        }
        else {
            Write-Host "failed !" -ForegroundColor "RED"
            Write-Host $p.stdout
            Write-Host $p.stderr
        }
    }

    $p
}

& $main