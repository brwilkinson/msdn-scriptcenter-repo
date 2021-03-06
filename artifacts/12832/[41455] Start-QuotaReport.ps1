Function Start-QuotaReport {
#Requires -Version 2.0
[CmdletBinding(DefaultParametersetName="QuotaLookup")]
 Param 
   (
    [Parameter(Mandatory=$false,
               Position=0,
               ParameterSetName="QuotaFile",   
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    $QuotaFile = "C:\PS\FileServers\dirquota-cluster.txt",
    [Parameter(Mandatory=$false,
               Position=0,
               ParameterSetName="QuotaLookup",   
               ValueFromPipeline=$false,
               ValueFromPipelineByPropertyName=$true)]
    [String]$QuotaLookup = "Role-SRV-FileClusterServers"      
   )#End Param 
Begin
{
    $erroractionpreference = 0
    Write-Host "Retrieving Quota Info . . ."
    # Run dirQuota on the server and save the file, then import to this.
    $QuotaPath,$QuotaStatus,$Limit,$Available,$AvailableWhole,$AvailableDecimal = $Null
    $i = 0
}#End begin
Process
{
switch ($PsCmdlet.ParameterSetName) 
    { 
        "QuotaFile"   {$dirquotaitems = (Get-Content $QuotaFile)}
        "QuotaLookup" {$dirquotaitems = Get-QADGroupMember $QuotaLookup | 
                                            ForEach-Object {
                                                $SB = {DirQuota Quota List}
                                                $Session = New-PSSession -ComputerName $_.Name
                                                Invoke-Command -Session $Session -ScriptBlock $SB
                                            }
                      }#QuotaLookup
    }

$dirquotaitems | ForEach-Object {
$pattern = '^.{24}'
#$_
        if ($_ -match "Quota Path:")
            {
                [String]$QuotaPath = ($_ -split $pattern)[1]
            }

        elseif ($_ -match "Quota Status:")
            {
                [String]$QuotaStatus = ($_ -split $pattern)[1]
            }

        elseif ($_ -match "Limit:")
            {
                [String]$LimitString,$LimitFigure,$LimitType = (($_ -split $pattern)[1] -split " ")
                [Int]$LimitWhole,[Int]$LimitDecimal = $LimitString.split(".")
            
                <#
                This accounts for Quota's with the following Limits: GB, MB, TB
                #>
                if ($LimitFigure -eq "TB")
                    {
                        $Limit = ($LimitWhole + ($LimitDecimal/100))*1024
                    }
                elseif ($LimitFigure -eq "GB")
                    {
                        $Limit = ($LimitWhole + ($LimitDecimal/100))
                    }
                elseif ($LimitFigure -eq "MB")
                    {
                        $Limit = ($LimitWhole + ($LimitDecimal/100))/1024
                    }
            }

        elseif ($_ -match "Used:")
            {
                [String]$UsedString,$UsedFigure,$PercentageUsed = (($_ -split $pattern)[1] -split " ")
                [Int]$UsedWhole,[Int]$UsedDecimal  = $UsedString.split(".")                
                
                <#
                This accounts for Quota's with the following Used amounts: GB, KB, MB, TB
                #>

                if ($UsedFigure -eq "TB")
                    {
                        $Used = [Math]::Round((($UsedWhole + ($UsedDecimal/100))*1024),2)
                    }
                elseif ($UsedFigure -eq "GB")
                    {
                        $Used = [Math]::Round(($UsedWhole + ($UsedDecimal/100)),2)
                    }
                elseif ($UsedFigure -eq "MB")
                    {
                        $Used = [Math]::Round((($UsedWhole + ($UsedDecimal/100))/1024),2)
                    }
                elseif ($UsedFigure -eq "KB")
                    {
                        $Used = [Math]::Round((($UsedWhole + ($UsedDecimal/100))/1024/1024),2)
                    }
            }

        elseif ($_ -match "Available:")
            {
                [String]$AvailableString,$AvailableFigure = (($_ -split $pattern)[1] -split " ")
                if ($AvailableString -eq "0")
                    {
                        [Int]$Available = 0
                    }
                else
                    {
                        <#
                        This accounts for Quota's with the following Available values: bytes, GB, KB, MB
                        #>

                        [Int]$AvailableWhole,[Int]$AvailableDecimal = $AvailableString.split(".")                
                        
                        if ($AvailableFigure -eq "GB")
                            {
                                $Available = ($AvailableWhole + ($AvailableDecimal/100))
                            }
                        elseif ($AvailableFigure -eq "MB")
                            {
                                $Available = ($AvailableWhole + ($AvailableDecimal/100))/1024
                            }
                        elseif ($AvailableFigure -eq "KB")
                            {
                                $Available = ($AvailableWhole + ($AvailableDecimal/100))/1024/1024
                            }
                    }                       

            }
     
If (($QuotaPath -ne $Null) -and ($QuotaStatus -ne $Null) -and ($Limit -ne $Null) -and ($Available -ne $Null) -and ($Used -ne $Null))
    { 
      [Int]$UsedPercentage = (($PercentageUsed -split "%")[0]).Substring(1)
      if ($UsedPercentage -gt 100)
        {
            $AvailablePC = 0
        }
      else
        {
            $AvailablePC = (100-$UsedPercentage)
        }  
      $Hash = @{
                QuotaPath    = $QuotaPath
                Status       = $QuotaStatus
                LimitGB      = $Limit
                LimitType    = ($LimitType).Substring(1,$LimitType.length-2)
                UsedGB       = $Used
                UsedPC       = $UsedPercentage
                AvailablePC  = $AvailablePC
                AvailableGB  = $Available
               }
      $Quota = New-Object PSObject -Property $Hash
      
      #$Quota | ft -AutoSize | Out-Host
      $Quota
      $UsedString,$Used,$QuotaPath,$QuotaStatus,$LimitType,$LimitString,$Limit,$AvailableString,$Available, `
      $AvailableFigure,$AvailableWhole,$AvailableDecimal,$UsedPercentage,$PercentageUsed = $Null
    }
Else
    {
        #Write-Host "Not full"
    }
} | Select-Object -Property QuotaPath,LimitGB,UsedGB,UsedPC,AvailableGB,AvailablePC,LimitType,Status


}#End Process
End
{
    "Thank you have a nice day" | Out-Host
}#End End

}#Start-QuotaReport
