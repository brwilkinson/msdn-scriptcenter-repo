function global:Get-BadPasswordInfo {
     
     #Requires -Version 2.0            
     [CmdletBinding()]            
     Param             
     (                       
          [Parameter(Position=1)]            
          [String]$User = $env:USERNAME,
          [String]$Domain = $env:USERDNSDOMAIN,
          [Int32]$TimeOffsetfromGMT = ((Get-WmiObject -Class win32_timezone | Select-Object -ExpandProperty Bias)/60)
     )#End Param
     
     Begin            
     {            
          $i=0
          Write-Warning "Checking domain controllers for bad password"
          Write-Warning "information . . . this may take some time. `n"
          
          $Properties = 'SamAccountName','logonCount','badPwdCount','LastBadPasswordAttempt',
               'BadLogonCount','LockedOut','AccountLockoutTime','LastLogon','LastLogoff'
          $SelectProperties = ,'DomainController' + $Properties
          $ADUserParameterHash=@{
            Identity   = $User
            Properties = $Properties
            ErrorAction='Stop'
            }
          
     }#Begin          
     Process            
     {
          # Test-Online is here:
          # http://gallery.technet.microsoft.com/scriptcenter/2789c120-48cc-489b-8d61-c1602e954b24
          # Get-DomainController is here:
          # http://gallery.technet.microsoft.com/scriptcenter/List-Domain-Controllers-in-2bec62a5
          Get-DomainController -Domain $Domain | Test-Online | ForEach-Object {
               $i++
               Write-Verbose "$i --> DC: $_"
               
               # Set the server to each unique domain controller.
               $ADUserParameterHash["Server"]=$_
               
               try {
                    # do the lookup for userinfo against that specific server
                    $UserInfo = Get-ADUser @ADUserParameterHash
                    
                    $ResultHash = @{
                    DomainController = $_
                    }
                    
                    $Properties | ForEach-Object {
                         if ($Userinfo.$_ -eq $False)
                         { 
                              $ResultHash[$_]=$Userinfo.$_ 
                         }
                         elseif ($Userinfo.$_)
                         { 
                              if ($_ -like "LastBad*")
                              {
                                   $ResultHash[$_]=(Get-Date $Userinfo.$_ )
                              }
                              elseif ($_ -like "Last*")
                              {
                                   $ResultHash[$_]=([datetime]::FromFileTime( $Userinfo.$_) )
                              }                    
                              else
                              {
                                   $ResultHash[$_]=$Userinfo.$_ 
                              }
                         }
                         else
                         {   
                              if ($_ -like "*count")
                              {
                                   $ResultHash[$_]=$Null
                              }
                              else
                              {
                                   $ResultHash[$_]=[Datetime]::Parse('01/01/1000')
                              }   
                         } 
                    }
                    
                    
                    New-Object -Type PSObject -Property $ResultHash  | 
                    Select-Object -Property $SelectProperties
               }
               Catch {
                    Write-Warning $_
               }
               
          } | Sort-Object -Property LastBadPasswordAttempt -Descending
          #Foreach-Object(Get-DomainController)
          
     }#Process
     
}#Get-BadPasswordtime