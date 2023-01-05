function Start-BicepDownloadArtifact
{
    param (
        [string]$Branch = 'main',
        [switch]$Latest,
        [int]$Limit = 40,
        [validateset('cli/cli', 'azure/bicep')]
        [string]$Repo = 'azure/bicep',
        [string]$DownloadPathBase = "$home/downloads",
        [string]$UnixInstallPath = '/usr/local/bin',
        [string[]]$EventTypes = @('push')
    )

    $DownloadPath = Join-Path -Path $DownloadPathBase -ChildPath "BicepInstall_$(Get-Date -Format yyyy-MM-dd-hh)"
    $Artifacts = switch ($Repo)
    {
        'cli/cli'
        {
            @(
                'bicep-setup-win-x64', 'vscode-bicep.vsix'
            )
        }

        'azure/bicep'
        {
            @(
                @{
                    platform    = 'Win32NT'
                    releasepath = 'bicep-setup-win-x64.exe'
                    dailypath   = 'bicep-setup-win-x64'
                    name        = 'bicep'
                },
                @{
                    platform    = 'Win32NT'
                    releasepath = 'vscode-bicep.vsix'
                    dailypath   = 'vscode-bicep.vsix'
                    name        = 'vscode-bicep.vsix'
                },
                @{
                    platform    = 'Unix'
                    releasepath = 'bicep-linux-x64'
                    dailypath   = 'bicep-release-linux-x64'
                    name        = 'bicep'
                }
            )
        }
    }

    # $Artifacts = $Artifacts | Where-Object platform -EQ $PSVersionTable.Platform
    Write-Output "Artifacts [$($Artifacts.length)]:`n$($Artifacts | Out-String)"

    Push-Location
    if (! (Test-Path -Path $DownloadPath))
    {
        New-Item -Path $DownloadPath -ItemType Directory -Verbose
    }
    Set-Location -Path $DownloadPath
    $Artifacts | ForEach-Object {
        Get-Item -Path ./$($_.releasepath), ./$($_.dailypath) -Verbose -EA 0 | Select-Object -Unique | Remove-Item -Verbose -ErrorAction SilentlyContinue
    }
    
    if ($Latest)
    {
        $BuildId = gh run list -R $Repo -L $Limit |
            ConvertFrom-Csv -Delimiter `t -Header STATE, STATUS, NAME, WORKFLOW, BRANCH, EVENT, ID, ELAPSED, AGE |
            Where-Object branch -EQ $Branch | Where-Object EVENT -In $EventTypes | Where-Object state -EQ completed | Where-Object status -EQ success |
            Select-Object -First 1 | ForEach-Object Id
        
        if (! ($BuildId))
        {
            return "No successful builds found in [$Limit] runs, pass in a higher limit."
        }

        # view run URL
        gh run view $BuildId -R $Repo | Select-Object -Last 1

        $Artifacts | ForEach-Object {
            $path = $_.dailypath
            gh run download $BuildId -R $Repo -n $path
        }
    }
    else
    {
        # view release URL (not working in linux?)
        gh release view -R $Repo | Select-Object -Last 1
        
        $Artifacts | ForEach-Object {
            $path = $_.releasepath
            gh release download -R $Repo -p $path
        }
    }

    $Artifacts | Where-Object platform -EQ $PSVersionTable.Platform | ForEach-Object {
        $platform = $_.platform
        $path = if ($Latest) { $_.dailypath }else { $_.releasepath }
        $name = $_.name
        Write-Verbose "App name is: [$name] path is [$path]" -Verbose

        switch ($platform)
        {
            'Unix'
            {
                if (!(Test-Path -Path $UnixInstallPath)) { New-Item -Path $UnixInstallPath -ItemType Directory }
                $destination = "$UnixInstallPath/$name"
                Write-Warning "destination is: [$destination]"
                sudo cp $path $destination
                sudo chmod +x $destination
                & $name --version
            }
            'Win32NT'
            {
                switch (Get-Item -Path $path* | ForEach-Object Extension)
                {
                    '.exe'
                    {
                        Start-Process -FilePath $Path -ArgumentList '/SILENT' -PassThru | Wait-Process
                        . $name --version
                    }

                    '.vsix'
                    {
                        code-insiders --install-extension $path --force
                    }
                }
            }
            'Default'
            {
                echo "no platform found"
            }
        }
    }
    Pop-Location
}
Set-Alias -Name GetBicep -Value Start-BicepDownloadArtifact

