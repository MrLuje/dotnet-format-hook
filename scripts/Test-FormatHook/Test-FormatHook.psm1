Function Start-Command ($commandPath, $commandArguments, $path = (Get-Location)) {
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
        Write-Error $_
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

function SetGitRepo () {
    if ($env:VERBOSE -eq "true") {
        $r = Start-Command "git" "init"
    }
    else {
        $r = Start-Command "git" "init -q"
    }
    $r = Start-Command "git" "config user.email 'a@a.com'"
    $r = Start-Command "git" "config user.name 'hey'"
    return $null
}

function Assert-GitInstalled() {
    if ((Test-Path ".git") -eq $false) {
        Write-Error "Git repo in test wasn't initialized"
        return $false
    }
    return $true
}

function Install-NugetPackage ($pathToCsProj, $pkg, $pkgSrc) {  
    $r = Start-Command "dotnet" "add $pathToCsProj package $pkg -s $pkgSrc"
    if ($r.ExitCode -ne 0) {
        Write-Error "Failed to install $pkg"
        return $false
    }
    return $true    
}

function Build-Solution ($pathToFolder = (Get-Location)) {
    if ($env:VERBOSE -eq "true") {
        Write-Host "Executing dotnet build"
    }
    
    return Start-Command "dotnet" "build /flp:v=diag" $pathToFolder 
}

function Assert-HookNotInstalled ($buildResult) {
    if ($buildResult.ExitCode -eq 0) {
        if ((Test-Path (Join-Path ".git" "format-hook.enabled")) -eq $true) {
            Write-Error ".git\format-hook.enabled is present but it should not"
            Write-Error $buildResult.stdout
            return $false
        }
    }
    else {
        Write-Error "dotnet build failed"
        Write-Error $buildResult.stdout
        return $false
    }    
    return $true
}

function Assert-HookInstalled ($buildResult) {
    if ($buildResult.ExitCode -eq 0) {
        if ((Test-Path (Join-Path ".git" "format-hook.enabled")) -eq $false) {
            Write-Error ".git\format-hook.enabled is missing"
            Write-Error $buildResult.stdout
            return $false
        }
    }
    else {
        Write-Error "dotnet build failed"
        Write-Error $buildResult.stdout
        return $false
    }    
    return $true
}

function New-FileBackup($filePath) {
    Copy-Item $filePath -Destination "$filePath.beforehook"
}

function Set-FileModification($filePath) {
    "       " + (Get-Content $filePath -Raw) | Set-Content $filePath
    New-FileBackup $filePath
}

function Start-CommitProcess($gitAddAll = $true) {
    if ($gitAddAll -eq $true) {
        git add .
    }
    $r = Start-Command "git" "commit -m format"
    return $r
}

function Assert-HookHasFormatted($commitResult) {    
    if ($commitresult.ExitCode -eq 0) {
        Write-Error "Git commit wasn't prevented by hook :("
        Write-Information "Re-running hooks in debug"
        # bash -x "hooks/pre-commit"
        return $false
    }
    elseif ($commitresult.ExitCode -eq 2) {
        # files formatted
        return $true
    }
    else {
        if ($commitresult.stderr.Contains("Code has been reformatted and changes were staged")) {
            return $true
        }
        Write-Error "Error $($commitresult.ExitCode)"
        Write-Error $commitresult.stderr
        return $false
    }
}

function Assert-HookHasNotFormatted($commitResult) {    
    if ($commitresult.ExitCode -eq 0) {
        return $true
    }
    elseif ($commitresult.ExitCode -eq 2) {
        # files formatted
        Write-Error "Git commit wasn't prevented by hook :("
        Write-Information "Re-running hooks in debug"
        # bash -x "hooks/pre-commit"
        return $false
    }
    else {
        if ($commitresult.stderr.Contains("Code has been reformatted and changes were staged")) {
            Write-Error "Git commit wasn't prevented by hook :("
            Write-Information "Re-running hooks in debug"
            # bash -x "hooks/pre-commit"
            return $false
        }
        Write-Error "Error $($commitresult.ExitCode)"
        Write-Error $commitresult.stderr
        return $false
    }
}

function Assert-DotnetToolLocallyInstalled($package) {
    $pathToConfig = (Join-Path ".config" "dotnet-tools.json")
    if (Test-Path $pathToConfig) {
        return ((Get-Content $pathToConfig) | Select-String $package).Length -gt 0
    }
    return $false
}

function Assert-SameFileContent($files, $beforeExtension = "beforehook") {
    $allMatches = $files | ForEach-Object { 
        $orig = "$_.$beforeExtension"
        $current = $_
        $origHash = (Get-FileHash $orig -Algorithm MD5 | Select-Object Hash).Hash
        $currentHash = (Get-FileHash $current -Algorithm MD5 | Select-Object Hash).Hash
        if ($origHash -ne $currentHash) {
            Write-Error "$current has been reformatted"
            return $false
        }
        return $true
    }

    return $allMatches
}

function Assert-DifferentFileContent($files, $beforeExtension = "beforehook") {
    $allMatches = $files | ForEach-Object { 
        $orig = "$_.$beforeExtension"
        $current = $_
        $origHash = (Get-FileHash $orig -Algorithm MD5 | Select-Object Hash).Hash
        $currentHash = (Get-FileHash $current -Algorithm MD5 | Select-Object Hash).Hash
        if ($origHash -eq $currentHash) {
            Write-Error "$current has not been reformatted"
            return $false
        }
        return $true
    }

    return $allMatches
}

function Install-DotnetTool($package, $version = "") {
    $arguments = "tool install $package --global "
    if ($version -ne "") {
        $arguments += "--version $version"
    }

    $r = Start-Command "dotnet" $arguments
    $env:PATH += ":/github/home/.dotnet/tools"
    return $r
}