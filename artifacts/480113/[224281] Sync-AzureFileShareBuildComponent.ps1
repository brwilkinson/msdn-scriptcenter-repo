#requires -Module Az.Storage
#requires -Module Az.Accounts

Param (
    [String]$BuildName = '4.2',
    [String]$ComponentName  = 'WebAPI',
    [String]$BasePath = 'D:\Builds'
)

# Azure File Share Info
[String]$SAName = 'saeastus2build'
[String]$RGName = 'rgglobalbuild'
[String]$ShareName = 'builds'

# if you already have a storage account you can get the context
$SA = Get-AzStorageAccount -ResourceGroupName $RGName -Name $SAName

$StorageShareParams = @{
    ShareName   = $ShareName
    Context     = $SA.Context
    ErrorAction = 'SilentlyContinue'
}

# *Builds/<ComponentName>/<BuildName>
# need to pass this in
$CurrentFolder = (Get-Item -Path $BasePath\$ComponentName\$BuildName ).FullName

# Create the Component\Build Directory
New-AzStorageDirectory @StorageShareParams -Path $ComponentName
New-AzStorageDirectory @StorageShareParams -Path $ComponentName\$BuildName

# Create the SubDirectories under the Build Directory and capture a list of the directory URI's
$SourceDirs = Get-ChildItem -Path $BasePath\$ComponentName\$BuildName -Directory -Recurse | foreach-object {
    $path=$_.FullName.Substring($Currentfolder.Length+1).Replace("\","/")
    Write-Output -InputObject "/$ShareName/$ComponentName/$BuildName/$path"
    New-AzStorageDirectory @StorageShareParams -Path $ComponentName\$BuildName\$Path -Verbose
}

# Copy up the files and capture a list of the files URI's
$SourceFiles = Get-ChildItem -Path $BasePath\$ComponentName\$BuildName -File -Recurse | foreach-object {
    $path = $_.FullName.Substring($Currentfolder.Length + 1).Replace("\","/")
    Write-Output -InputObject "/$ShareName/$ComponentName/$BuildName/$path"
    Set-AzStorageFileContent @StorageShareParams -Source $_.FullName -Path $ComponentName\$BuildName\$Path -Verbose -Force
}

# Helper Function: Find all of the files in the share including subfolders
function Get-AZFile
{
    param (
        $Path
    )
    
    Get-AzStorageFile @StorageShareParams -Path $Path | Get-AzStorageFile | ForEach-Object {

        if ($_.GetType().Fullname -eq 'Microsoft.Azure.Storage.File.CloudFileDirectory')
        {
            Write-Warning "$($_.Uri.LocalPath) is directory"
             
            $newPath = -join ($_.uri.segments | select -skip 2)
            Get-AZFile -Path $newPath
        }
        else
        {
            Write-Output $_.Uri.LocalPath
        }
    }
}

# Helper Function: Find all of the dirs in the share including subfolders
function Get-AZDir
{
    param (
        $Path
    )
    
    Get-AzStorageFile @StorageShareParams -Path $Path | Get-AzStorageFile | ForEach-Object {

        if ($_.GetType().Fullname -eq 'Microsoft.Azure.Storage.File.CloudFileDirectory')
        {
            Write-Output $_.Uri.LocalPath
             
            $newPath = -join ($_.uri.segments | select -skip 2)
            Get-AZDir -Path $newPath
        }
        else
        {
            Write-Verbose "$($_.Uri.LocalPath) is file" -Verbose
        }
    }
}

# Find all of the files in the share including subfolders
$Path = "$ComponentName\$BuildName\"
$DestinationFiles = Get-AZFile -Path $Path
$DestinationDirs = Get-AZDir -Path $Path

# Compare the new files that were uploaded to the files already on the share
# these should be deleted from the Azure File Share
$FilestoRemove = Compare-Object -ReferenceObject $DestinationFiles -DifferenceObject $SourceFiles | 
                        Where SideIndicator -eq "<=" | foreach InputObject

# Compare the new dirs that were uploaded to the dirs already on the share
# these should be deleted from the Azure File Share
$DirstoRemove = Compare-Object -ReferenceObject $DestinationDirs -DifferenceObject $SourceDirs | 
                        Where SideIndicator -eq "<=" | foreach InputObject                        
                        
# Remove the old Files
$FilestoRemove | ForEach-Object {
    $FiletoRemove = ($_ -split '/' | select -Skip 2) -join '/'
    Write-Verbose "/$FiletoRemove" -Verbose
    Remove-AzStorageFile @StorageShareParams -Path "/$FiletoRemove" #-whatif
}

# Remove the old Dirs, longest paths (child dirs) first
$DirstoRemove | sort -Descending | ForEach-Object {
    $DirtoRemove = ($_ -split '/' | select -Skip 2) -join '/'
    Write-Warning "/$DirtoRemove"
    Remove-AzStorageDirectory @StorageShareParams -Path "/$DirtoRemove" #-whatif
}