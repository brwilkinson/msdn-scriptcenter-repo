function Global:Add-FunctionToModule()
{
#Requires -Version 2.0
[CmdletBinding()]
 Param 
   (
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$false,
               ValueFromPipelineByPropertyName=$false)]
    [String]$FunctionName,
    [String]$ModuleName = "BRW"
   )#End Param

Begin
{
    $BasePath = Get-Module $ModuleName -ListAvailable -ea Stop | 
                Select -ExpandProperty ModuleBase -First 1
    if ( $BasePath.length -ne 0 )
        {
            "`nAdding Function to Module $ModuleName . . .`n"
            "Module base path: $BasePath"
        }
    else
        {
            "Module $ModuleName was not found."
            Break
        }
}#Begin
Process
{
    $ExportAll = 'Export-ModuleMember -function * -alias *'
    $Current = $psise.CurrentFile.FullPath
    $Filename = $FunctionName + '.ps1'
    [String]$Functionpath = '. $psScriptRoot\' + $Filename
    $currentfiles = Get-Content -Path "$BasePath\$ModuleName.psm1"
    if (!($currentfiles -contains $Functionpath))
        {
            $currentfiles = $currentfiles[0..($currentfiles.count-2)] + $Functionpath + $ExportAll
            $currentfiles | Out-File -FilePath "$BasePath\$ModuleName.psm1" -Encoding ASCII
        }
    else 
        {
            "Function is already in $ModuleName Mods file."
            Remove-Item -Path $Current -Confirm
        }
    
    $psise.CurrentFile.SaveAs("$BasePath\$Filename")
    
}#Process
End
{
    Import-Module $ModuleName -Force -Global
    $Filename, $Functionpath = $Null
}#End


}#Function Add-FunctionToModule
