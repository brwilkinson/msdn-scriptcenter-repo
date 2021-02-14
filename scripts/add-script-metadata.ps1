$repoPath = 'D:\Repos'
$path = "$repoPath\msdn-scriptcenter-repo\_site\artifacts"
$file = "$repoPath\msdn-scriptcenter-repo\_data\scripts.json"

$data = Get-Content -Path $file | ConvertFrom-Json -Depth 5
$userData = $data.userProject | ForEach-Object {

    $project = $_.ProjectId
    try
    {
        $files = Get-ChildItem -Path $Path\$project -Filter *.ps1 -ea stop
        if ($Files.count -ne 1)
        {
            Write-Warning 'more than 1 powershell script'
            $_ | Add-Member -MemberType NoteProperty -Name ScriptFile -Value '' -Force
            $_
        }
        else
        {
            $_ | Add-Member -MemberType NoteProperty -Name ScriptFile -Value $Files.Name -Force
            $_
        }
    }
    catch
    {
        write-verbose "$project has no scripts" -Verbose
    }
}

$data.userProject = $userData
$data | ConvertTo-Json | Set-Content -Path $File