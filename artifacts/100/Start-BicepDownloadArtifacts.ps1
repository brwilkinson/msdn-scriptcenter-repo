function Start-BicepDownloadArtifact
{
    param (
        [switch]$Latest,
        
        $Artifacts = @(
            'bicep-setup-win-x64', 'vscode-bicep.vsix'
        )
    )
    Push-Location
    Set-Location -Path "$home\Downloads\"
    $Artifacts | ForEach-Object {
        Get-Item .\$_* | Remove-Item -Verbose -ErrorAction SilentlyContinue
    }
    
    if ($Latest)
    {
        gh run list -R azure/bicep | ConvertFrom-Csv -Delimiter `t -Header STATE, STATUS, NAME, WORKFLOW, BRANCH, EVENT, ID, ELAPSED, AGE |
            Where-Object branch -EQ main | Where-Object state -EQ completed | Where-Object status -EQ success |
            Select-Object -First 1 | ForEach-Object {
                Write-Verbose $_ -Verbose
                $BuildId = $_.Id
                $Artifacts | ForEach-Object {
                    gh run download $BuildId -R azure/bicep -n $_
                }
            }
    }
    else 
    {
        $Artifacts | ForEach-Object {
            gh release download -R azure/bicep -p $_*
        }
    }

    code-insiders --install-extension vscode-bicep.vsix --force --log off
    .\bicep-setup-win-x64.exe /SILENT
    Pop-Location
}
New-Alias -Name GetBicep -Value Start-BicepDownloadArtifact

