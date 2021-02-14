<#
.Synopsis
   Search for WMI Classes through all available Namespaces
.DESCRIPTION
   This script acts like a WMI Explorer. You can search for available namespaces and classes. You can
   also search for available properties OR methods
.EXAMPLE
   Search-WMINameSpace -ClassFilter print -MethodFilter add -MethodsOnly

   Name               NameSpace                 Methods
   ----               ---------                 -------
   MSFT_PrinterDriver root\StandardCimv2        Add    
   MSFT_PrinterDriver root\StandardCimv2\MS_409 Add       
.EXAMPLE
   Search-WMINameSpace -ClassFilter process -MethodFilter create

      NameSpace: ROOT\CIMV2

   Name          Methods                                       Propertiea
   ----          -------                                       ----------
   Win32_Process {Create, Terminate, GetOwner, GetOwnerSid...} {Caption, CommandLine, CreationClassName, CreationDate...}

       NameSpace: ROOT\CIMV2\ms_409

   Name          Methods                                       Properties
   ----          -------                                       ----------
   Win32_Process {Create, Terminate, GetOwner, GetOwnerSid...} {Caption, CommandLine, CreationClassName, CreationDate...}
.EXAMPLE
   Search-WMINameSpace -ClassFilter virtualization | ft -AutoSize

       NameSpace: ROOT\virtualization

   Name                                     Methods Properties                     
   ----                                     ------- ----------                     
   Msvm_VirtualizationComponentRegistration {}      {Component, ResourceType}      
   Msvm_VirtualizationComponent             {}      {CLSID, Context, Enabled, Name}
   
     . . . some output truncated . . .
.EXAMPE
   Search-WMINameSpace -ClassFilter printersetting -PropertiesOnly | fl


   Name       : Win32_PrinterSetting
   NameSpace  : root\CIMV2
   Properties : Element, Setting

   Name       : RSOP_PolmkrPrinterSetting
   NameSpace  : root\RSOP\User
   Properties : creationTime, GPOID, id, name, polmkrBaseCseGuid, polmkrBaseGpeGuid, polmkrBaseGpoDisplayName, polmkrBaseGpoGuid, polmkrBaseHash, polmkrBaseInstanceXml, polmkrBaseKeyValues, 
                 precedence, SOMID

   Name       : RSOP_PolmkrLocalPrinterSetting
   NameSpace  : root\RSOP\User
   Properties : creationTime, GPOID, id, name, polmkrBaseCseGuid, polmkrBaseGpeGuid, polmkrBaseGpoDisplayName, polmkrBaseGpoGuid, polmkrBaseHash, polmkrBaseInstanceXml, polmkrBaseKeyValues, 
                 precedence, SOMID
     . . . some output truncated . . .
.EXAMPLE
   Search-WMINameSpace -ClassFilter DFS -MethodFilter create -MethodsOnly | ft -AutoSize

   Name          NameSpace         Methods
   ----          ---------         -------
   Win32_DfsNode root\CIMV2        Create 
   Win32_DfsNode root\CIMV2\ms_409 Create
#>

function Search-WMINameSpace {
param ([Parameter(Position=0)]
        $ClassFilter = "*",
        $NameSpace = "root",
        $MethodFilter = "*",
        [Switch]$MethodsOnly,
        [Switch]$PropertiesOnly,
        $ComputerName = $env:COMPUTERNAME
)

    #-------------------------
    # Helper Function recurse through ALL subnamespaces
    function __Get-MyNameSpace {
    param (
            $NameSpace = "root",
            $Class = "__NameSpace",
            $ComputerName = $env:COMPUTERNAME
    )

    if ($i -eq 0)
        {
            "Root"
        }
    $i++
    
    Get-WmiObject -Namespace $NameSpace -Class $Class -ComputerName $ComputerName | ForEach-Object {

        if ($_.Name)
        {           
            $NameSpace + "\" + $_.Name
            __Get-MyNameSpace -NameSpace "$NameSpace\$($_.Name)" -ComputerName $ComputerName
        }


    }#ForEach-Object
    }#__Get-MyNameSpace

    # Call to get ALL of the namespaces starting by default at root.
    
    $i = 0
    __Get-MyNameSpace -NameSpace $NameSpace -ComputerName $ComputerName | ForEach-Object {

    # Get the details of the classes within the current namespace
    $CurrentNameSpace = $_
    Get-WmiObject -List -Namespace $CurrentNameSpace  -Class ("*" + $ClassFilter + "*") | ForEach-Object {
        
     if ( $MethodFilter -ne "*" )
        {
            if ( $_.Methods.Name -contains $MethodFilter )
                {    
                    if ($MethodsOnly)
                        {
                            $_ | where {$_.methods.count -ne 0} | select Name, @{Name="NameSpace";Expression={$CurrentNameSpace}}, 
                                @{Name="Methods";Expression={$_.methods.Name -join ", "}}
                        }
                    elseif ($PropertiesOnly)
                        {
                            $_ | where {$_.properties.count  -ne 0} | select Name, @{Name="NameSpace";Expression={$CurrentNameSpace}}, 
                                @{Name="Properties";Expression={$_.properties.Name -join ", "}}
                        }
                    else
                        {
                            $_ 
                        }
                }
        }
    else
        {
            if ($MethodsOnly)
                {
                    $_ | where {$_.methods.count -ne 0} | select Name, @{Name="NameSpace";Expression={$CurrentNameSpace}}, 
                        @{Name="Methods";Expression={$_.methods.Name -join ", "}}
                }
            elseif ($PropertiesOnly)
                {
                    $_ | where {$_.properties.count  -ne 0} | select Name, @{Name="NameSpace";Expression={$CurrentNameSpace}}, 
                        @{Name="Properties";Expression={$_.properties.Name -join ", "}}
                }
            else
                {
                    $_ 
                }
        }
    }

    }

}#Search-WMINameSpace
