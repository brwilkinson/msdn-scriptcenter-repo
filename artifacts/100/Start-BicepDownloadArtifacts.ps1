function Start-BicepDownloadArtifact
{
    param (
        [switch]$Branch = 'main',

        [switch]$Latest,

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
        $BuildId = gh run list -R $Repo |
            ConvertFrom-Csv -Delimiter `t -Header STATE, STATUS, NAME, WORKFLOW, BRANCH, EVENT, ID, ELAPSED, AGE |
            Where-Object branch -EQ $Branch | Where-Object state -EQ completed | Where-Object status -EQ success |
            Select-Object -First 1 | foreach Id
        
        gh run view $BuildId -R $Repo | select -last 1

        $Artifacts | ForEach-Object {
            gh run download $BuildId -R $Repo -n $_
        }
    }
    else
    {
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

