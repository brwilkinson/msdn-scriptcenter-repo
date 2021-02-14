<#
.Synopsis
   Find AzureRM VM Sizes
.DESCRIPTION
   Find AzureRM VM Sizes, Filter by the number of cores that you need,

   Different hardware sizes and VM offerings are available at different Data Centers
.EXAMPLE
    Find-AzureRMVMSize

    Name                   NumberOfCores MemoryInMB MaxDataDiskCount OSDiskSizeInMB ResourceDiskSizeInMB
    ----                   ------------- ---------- ---------------- -------------- --------------------
    Standard_A0                        1        768                1        1047552                20480
    Basic_A0                           1        768                1        1047552                20480
    Standard_B1s                       1       1024                2        1047552                 2048
    ...
.EXAMPLE
    Find-AzureRMVMSize -Verbose
    VERBOSE: Searching for VM Sizes in region: EASTUS2

    Name                   NumberOfCores MemoryInMB MaxDataDiskCount OSDiskSizeInMB ResourceDiskSizeInMB
    ----                   ------------- ---------- ---------------- -------------- --------------------
    Standard_A0                        1        768                1        1047552                20480
    Basic_A0                           1        768                1        1047552                20480
    ...
.EXAMPLE
    Find-AzureRMVMSize -Verbose -NumCores 2 -DisplayOutput Grid
.EXAMPLE
    Find-AzureRMVMSize -Verbose -NumCores 2 -DisplayOutput Table
    VERBOSE: Searching for VM Sizes in region: EASTUS2

    MaxDataDiskCount MemoryInMB Name                   NumberOfCores OSDiskSizeInMB ResourceDiskSizeInMB
    ---------------- ---------- ----                   ------------- -------------- --------------------
                   4       3584 Standard_A2                        2        1047552               138240
                   4       3584 Basic_A2                           2        1047552                61440
                   4       4096 Standard_B2s                       2        1047552                 8192
    ...
#>

Function Find-AzureRMVMSize {
[cmdletbinding()]
param (
   # Virtual Machine sizes are dependent on the region they are deployed
   [String]$Location = 'EASTUS2',

   # Output format
   [validateset('Grid','Table','Object')]
   [string]$DisplayOutput = 'Object',

   # The number of cores to filter on the query
   [int]$NumCores
)

    $VMSizes =  Get-AzureRmVMSize -Location $Location | Sort -Property MemoryInMB
    Write-Verbose -Message "Searching for VM Sizes in region: $Location"

    if ($NumCores)
    {
       $VMSizes = $VMSizes | Where-Object { $_.NumberofCores -eq $NumCores}
    }

    if ($DisplayOutput -eq 'Object')
    { 
        $VMSizes
    }
    elseif ($DisplayOutput -eq 'Grid')
    {
        $VMSizes | Select -Property Name,NumberOfCores,MemoryInMB,MaxDataDiskCount,OSDiskSizeInMB,ResourceDiskSizeInMB | Out-GridView 
    }
    elseif ($DisplayOutput -eq 'Table')
    {
        # sort by memory
        $VMSizes |  
        Select -Property Name,NumberOfCores,MemoryInMB,MaxDataDiskCount,OSDiskSizeInMB,ResourceDiskSizeInMB | ft -AutoSize
    }
    
}