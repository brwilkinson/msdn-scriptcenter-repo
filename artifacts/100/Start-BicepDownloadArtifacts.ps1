function Start-BicepDownloadArtifact
{
    param (
        [string]$Branch = 'main',

        [switch]$Latest,

        [int]$Limit = 40,

        [string]$Repo = 'azure/bicep',

        [string]$DownloadPath = "$home\Downloads\",

        $Artifacts = @(
            'bicep-setup-win-x64', 'vscode-bicep.vsix'
        )
    )
    Push-Location
    Set-Location -Path $DownloadPath
    $Artifacts | ForEach-Object {
        Get-Item .\$_* | Remove-Item -Verbose -ErrorAction SilentlyContinue
    }
    
    if ($Latest)
    {
        $BuildId = gh run list -R $Repo -L $Limit |
            ConvertFrom-Csv -Delimiter `t -Header STATE, STATUS, NAME, WORKFLOW, BRANCH, EVENT, ID, ELAPSED, AGE |
            Where-Object branch -EQ $Branch | Where-Object state -EQ completed | Where-Object status -EQ success |
            Select-Object -First 1 | foreach Id
        
        if (! ($BuildId))
        {
            return "No successful builds found in [$Limit] runs, pass in a higher limit."
        }

        # view run URL
        gh run view $BuildId -R $Repo | select -last 1

        $Artifacts | ForEach-Object {
            gh run download $BuildId -R $Repo -n $_
        }
    }
    else
    {
        # view release URL
        gh release view -R $Repo | select -last 1
        
        $Artifacts | ForEach-Object {
            gh release download -R $Repo -p $_*
        }
    }

    code-insiders --install-extension vscode-bicep.vsix --force
    .\bicep-setup-win-x64.exe /SILENT
    Pop-Location
}
New-Alias -Name GetBicep -Value Start-BicepDownloadArtifact

