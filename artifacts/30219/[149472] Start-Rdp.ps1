<#
.Synopsis
   Connect to RDP in a window the exact same size as your powershell console window that you called the function
.DESCRIPTION
   Connect to RDP in a window the exact same size as your powershell console window that you called the function,
   Creates a RDP windows instead of fullscreen, perfect for demo's or working on large monitors.
.EXAMPLE
   Start-Rdp -FilePath $home\downloads\vmDev5-01.rdp
.EXAMPLE
   Start-Rdp -Computer win10-ws
.EXAMPLE
   Start-Rdp -Computer ts.domaain.com:3390 -Force
.EXAMPLE
   Start-Rdp -ComputerName tspub.domain.com
#>

function Start-Rdp
{
   [cmdletbinding()]
   Param(
      [parameter(Mandatory=$true,ParameterSetName='FilePath')]
      [String]$FilePath,

      [parameter(Mandatory=$true,ParameterSetName='ComputerName')]
      [String]$ComputerName,
      
      [parameter(Mandatory=$true,ParameterSetName='Computer')]
      [ValidateSet( 
        'win10-ws', 
        'Server2012r2-01', 
        'Server2012r2-01.mydomain.com', 
        'Server2012r2-01.mydomain.com:3390', 
        'MyVM2.mydomain.com')] 
      [alias('CN')]		
      [String]$Computer = 'ts.mydomain.com',
      [Switch]$Force = $true
   )
	
   $code = @'
using System;
using System.Runtime.InteropServices;
namespace RDP
{
    public class WinApi
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT
        {
            public int left;
            public int top;
            public int right;
            public int bottom;
        }

        public class User32
        {
            [DllImport("user32.dll")]
            public static extern IntPtr GetClientRect(IntPtr hWnd,ref RECT rect);
            [DllImport("user32.dll")]
            public static extern IntPtr GetWindowRect(IntPtr hWnd,ref RECT rect);
        }
    }
}
'@
   Add-Type $code -IgnoreWarnings -WarningAction SilentlyContinue
	
   $rect = New-Object RDP.WinApi+RECT
   $hwnd = (Get-Process -Id $pid).MainWindowHandle
   $null = [RDP.WinApi+User32]::GetClientRect($hwnd, [ref]$rect)
	
   switch ($PSCmdlet.ParameterSetName)
   {
      'ComputerName'{ $Address = $ComputerName }
      'Computer'    { $Address = $Computer }
   }
	
   try
   {
      
       switch -Wildcard ($PSCmdlet.ParameterSetName)
       {
         'File*' {
            mstsc.exe $FilePath /w:$($rect.right) /h:$($rect.bottom)    
          }
         'Computer*'{
            # see if 3389 is responding
            if (! $Force)
            {
            $Result = Test-NetConnection -ComputerName $Address -CommonTCPPort RDP -WarningAction SilentlyContinue
            }

            # if it's responding connect
            if ($Result.TcpTestSucceeded -or $Force)
            {
                mstsc.exe /v:$Address /w:$($rect.right) /h:$($rect.bottom)
            }
            #else
            #{
            #   # If it's not responding, enable the NIC
            #   $VMNic = Get-NetAdapter -Name *VEthNAT* -ErrorAction SilentlyContinue
            #   if ($VMNic.Status -ne 'Enabled')
            #   {
            #          Write-Warning 'Trying to enable VMNic'
            #          $VMNic | Enable-NetAdapter -Confirm:$False
            #          Start-Sleep -Seconds 2
            #          
            #          # if now respoding try connect again
            #          $Result = Test-NetConnection -ComputerName $Address -CommonTCPPort RDP
            #          if ($Result.PingSucceeded)
            #          {
            #             mstsc.exe /v:$Address /w:($rect.right) /h:($rect.bottom)
            #          }
            #          else
            #          {
            #             Write-Warning "Cannot connect to $Address"
            #          }
            #   }
            #}#Else
            }#Computer
         }#Switch
   }
   catch
   {
      Write-Warning $_
   }
	
}