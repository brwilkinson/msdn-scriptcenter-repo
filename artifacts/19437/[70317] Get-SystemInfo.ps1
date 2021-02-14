function global:Get-SystemInfo {

#Requires -Version 3.0
[CmdletBinding()]
 Param 
   (
    [Parameter(Position=0,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [String[]]$ComputerName = ($Env:COMPUTERNAME),
    [Parameter(Position=1)]
    [PSCredential]$Credential,
    [ValidateScript({Test-Path -Path $_})]
    [String]$LogDir = "$Home\Documents"        
   )#End Param 

Begin
{
 Write-Verbose "Retrieving Computer Info . . ."
 if ($Credential)
    {
        $PSDefaultParameterValues = $Global:PSDefaultParameterValues.Clone()
        $PSDefaultParameterValues["Get-WmiObject:Credential"]=$Credential  
    }
}
Process
{
    $ComputerName | ForEach-Object { 

    Write-Verbose ">> ComputerName: $_"

    $ErrorActionPreference = "SilentlyContinue"
    
    $os = Get-WmiObject -class Win32_OperatingSystem -ComputerName $_
    
    $sys = Get-WmiObject -Class win32_Computersystem -ComputerName $_
    
    $bios = Get-WmiObject -Class win32_Bios -ComputerName $_ 
    
    $PageFile = Get-WmiObject Win32_PageFileSetting -ComputerName $_ | 
        Select Name, InitialSize, MaximumSize | Format-Table -AutoSize | Out-String
    
    $Volume = Get-VolumeWin32 -ComputerName $_ | 
        Select Name,VolumeName,CapacityGB,UsedGB,FreeGB,FreePC | 
        ft -AutoSize | Out-String
    
    $Network = (Get-WmiObject -class win32_NetworkAdapterConfiguration -ComputerName $_  | 
        ForEach-Object { $_.DefaultIPGateway } | Out-String).Split("`n")[0]
    
    $CPU = @(Get-WmiObject -Class Win32_Processor -ComputerName $_ )[0]

    if (($os -eq $Null) -and ($sys -eq $Null) -and ($bios -eq $Null))
        {
          $_ | Out-File -FilePath $LogDir\nowmiHosts.txt -noclobber -Append
        }

    if ($os.LastBootupTime)
        {
        $LastBoot = $os.ConvertToDateTime($os.LastBootupTime)
        }
    if ($os.InstallDate)
        {
        $InstallDate = $os.ConvertToDateTime($os.InstallDate)
        }
    if ($sys.Name)
        {
        $CompName = $sys.Name.toUpper()
        }
    if ($sys.TotalPhysicalMemory)
        {
        $Memory=($sys.TotalPhysicalMemory)/1MB -as [int]
        }
    if ($Volume)
        {
            $Volume = $Volume.Substring(2,$Volume.length-9)
        }
    else
        {
            $Volume = @"
Please download and dot source the following function:
>> http://gallery.technet.microsoft.com/scriptcenter/74884d85-c0b5-446a-be04-3d411a6dce2f
"@
        }

    if ($Pagefile)
        {
            $PageFile = $PageFile.Substring(1,$PageFile.length-5)
        }
    else {$PageFile = "Automatic"}

    [PSCustomObject][Ordered]@{ 
        Computername   =$CompName 
        OperatingSystem=$os.Caption
        OSVersion      =$os.Version
        OSArchitecture =$os.OSArchitecture
        CPUName        =$CPU.Name
        CPUDescription =$CPU.Description
        CPUAddressWidth=$CPU.AddressWidth
        WindowsDir     =$os.WindowsDirectory
        LastBoot       =$LastBoot
        InstallDate    =$InstallDate
        BiosVersion    =$bios.version 
        SerialNumber   =$bios.SerialNumber
        TotalPhysMemMB =$Memory
        Vendor         =$sys.Manufacturer 
        Model          =$sys.Model
        Owner          =$sys.PrimaryOwnerName
        DefaultGateway =$Network
        PageFileInfo   =$PageFile
        Volume         =$Volume
        }
    
    $ErrorActionPreference = "Continue"
    
    # The following used for testing. 
    #$LastBoot,$InstallDate,$os,$sys,$bios,$CompName,$InstallDate,$LastBoot,$Memory,$PageFile,$Volume = $Null
     
  }

}

}#Get-SystemInfo