#requires -Module Az.Storage
#requires -Module Az.Accounts

<#
.SYNOPSIS
    Stage Files from a Build on Azure Storage (File Share), for Deployment
.DESCRIPTION
    Stage Files from a Build on Azure Storage (File Share), for Deployment. Primarily used for a PULL mode deployment where a Server can retrieve new builds via Desired State Configuration.
.EXAMPLE
    Sync-AzureFileShareBuildComponent -ComponentName WebAPI -BuildName 5.3 -BasePath "F:\Builds\WebAPI"

    Sync a local Build
.EXAMPLE
    Sync-AzureFileShareBuildComponent -ComponentName $(ComponentName) -BuildName $(Build.BuildNumber) -BasePath "$(System.ArtifactsDirectory)/_$(ComponentName)/$(ComponentName)"

    As seen in an Azure DevOps pipeline
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Updated 02/16/2021 
        - Added to Function instead of Script
        - Added examples
        - Updated to work with the newer AZ.Storage Module tested with 3.2.1
#>

function Sync-AzureFileShareBuildComponent
{
    Param (
        [String]$BuildName = '4.2',
        [String]$ComponentName = 'WebAPI',
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
    $SourceDirs = Get-ChildItem -Path $BasePath\$ComponentName\$BuildName -Directory -Recurse | ForEach-Object {
        $path = $_.FullName.Substring($Currentfolder.Length + 1).Replace('\', '/')
        Write-Output -InputObject "/$ShareName/$ComponentName/$BuildName/$path"
        New-AzStorageDirectory @StorageShareParams -Path $ComponentName\$BuildName\$Path -Verbose
    }

    # Copy up the files and capture a list of the files URI's
    $SourceFiles = Get-ChildItem -Path $BasePath\$ComponentName\$BuildName -File -Recurse | ForEach-Object {
        $path = $_.FullName.Substring($Currentfolder.Length + 1).Replace('\', '/')
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

            if ($_.GetType().Name -eq 'AzureStorageFileDirectory')
            {
                Write-Warning "$($_.CloudFileDirectory.Uri.LocalPath) is directory"

                $newPath = -join ($_.CloudFileDirectory.uri.segments | Select-Object -Skip 2)
                Get-AZFile -Path $newPath
            }
            else
            {
                Write-Output $_.CloudFile.Uri.LocalPath
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

            if ($_.GetType().Name -eq 'AzureStorageFileDirectory')
            {
                Write-Output $_.CloudFileDirectory.Uri.LocalPath
                $newPath = -join ($_.CloudFileDirectory.uri.segments | Select-Object -Skip 2)
                Get-AZDir -Path $newPath
            }
            else
            {
                Write-Verbose "$($_.CloudFile.Uri.LocalPath) is file" -Verbose
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
        Where-Object SideIndicator -EQ '<=' | ForEach-Object InputObject

    # Compare the new dirs that were uploaded to the dirs already on the share
    # these should be deleted from the Azure File Share
    $DirstoRemove = Compare-Object -ReferenceObject $DestinationDirs -DifferenceObject $SourceDirs | 
        Where-Object SideIndicator -EQ '<=' | ForEach-Object InputObject

    # Remove the old Files
    $FilestoRemove | ForEach-Object {
        $FiletoRemove = ($_ -split '/' | Select-Object -Skip 2) -join '/'
        Write-Verbose "/$FiletoRemove" -Verbose
        Remove-AzStorageFile @StorageShareParams -Path "/$FiletoRemove" #-whatif
    }

    # Remove the old Dirs, longest paths (child dirs) first
    $DirstoRemove | Sort-Object -Descending | ForEach-Object {
        $DirtoRemove = ($_ -split '/' | Select-Object -Skip 2) -join '/'
        Write-Warning "/$DirtoRemove"
        Remove-AzStorageDirectory @StorageShareParams -Path "/$DirtoRemove" #-whatif
    }
}