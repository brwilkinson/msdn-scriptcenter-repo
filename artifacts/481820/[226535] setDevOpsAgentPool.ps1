Param (
    [validateset('AZE2','AZC1')]
    [String]$Prefix = 'AZC1',

    [validateset('S1','D2','T3','Q4','U5','P6')]
    [String]$Environment = "D1",

    [pscredential]$DomainCreds,

    [pscredential]$DevOpsAgentPATToken
)

# This is the metadata for the pools/agents that you want to install.
$DevOpsAgentPresent = @{ 
    orgUrl       = "https://dev.azure.com/MyDevOpsAgent/"
    AgentVersion = '2.165.0'
    AgentBase    = "F:\Source\vsts-agent"

    # Example 1 Pool with 2 agents
    Agents       = @{pool = "{0}-{1}-Apps1";name = "{0}-{1}-Apps03";Ensure = 'Present';Credlookup = 'DomainCreds' },
                    @{pool = "{0}-{1}-Apps1";name = "{0}-{1}-Apps04";Ensure = 'Present';Credlookup = 'DomainCreds' }
}

$credlookup = @{
    "DomainCreds" = $DomainCreds
    "DevOpsPat"   = $DevOpsAgentPATToken
}

Foreach ($DevOpsAgent in $DevOpsAgentPresent)
{
    #region Download the agent
    $DevOpsOrganization = $DevOpsAgent.orgUrl | split-Path -Leaf
    $AgentFile = "vsts-agent-win-x64-$($DevOpsAgent.agentVersion).zip"
    $AgentFilePath = "$($DevOpsAgent.AgentBase)\$AgentFile"
    $URI = "https://vstsagentpackage.azureedge.net/agent/$($DevOpsAgent.agentVersion)/$AgentFile"
    
    if (-not (Test-Path -Path $AgentFilePath))
    {
        mkdir -Path $DevOpsAgent.AgentBase -Force -EA ignore
        Invoke-WebRequest -uri $URI -OutFile $AgentFilePath -verbose
    }
    #endregion 

    # Find the unique Pool names
    $Pools = $DevOpsAgent.Agents.pool | select -unique
    $mypatp = $credlookup['DevOpsPat'].GetNetworkCredential().password
    $s = [System.Text.ASCIIEncoding]::new()
    $PatBasic = [System.Convert]::ToBase64String($s.GetBytes(":$mypatp"))

    foreach ($pool in $Pools)
    {
        $myPool = ($pool -f $Prefix,$environment)

        #region Test if the pools exists
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/pools/get%20agent%20pools?view=azure-devops-rest-6.0
        #$PoolName = $using:myPool
        $PoolName = $myPool

        $headers = @{
            #'Authorization' = "Basic $($using:PatBasic)"
            'Authorization' = "Basic $($PatBasic)"
            'Accept'        = 'application/json'
        }       
        $Params = @{  
            Method          = 'GET' 
            Headers         = $headers
            UseBasicParsing = $true 
            ErrorAction     = 'Stop' 
            ContentType     = "application/json" 
            OutVariable     = "result" 
        }

        #$URI = 'https://dev.azure.com/{0}/_apis/distributedtask/pools' -f $Using:DevOpsOrganization
        $URI = 'https://dev.azure.com/{0}/_apis/distributedtask/pools' -f $DevOpsOrganization
        $URI += "?poolName=$($PoolName)&poolType=automation"
        $URI += '?api-version=6.0-preview.1'
        $Params['Uri'] = $URI
        $r = Invoke-WebRequest @Params -Verbose
        $agentPools = $result[0].Content | convertfrom-json
                            
        if ($agentPools.count -gt 0)
        {
            $Selfhosted = $agentpools.value | where -Property isHosted -eq $false
            $out = $Selfhosted | 
                select name,id,createdOn,isHosted,poolType | ft -autosize | out-String
        Write-Verbose `n$out -verbose
        $true
    }
    else 
    {
        Write-Verbose "PoolName $PoolName not found" -verbose
        $false
        #region Set the new Pool
        # https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/pools/add?view=azure-devops-rest-6.0
        #$PoolName = $using:myPool
        $PoolName = $myPool

        $headers = @{
            #'Authorization' = "Basic $($using:PatBasic)"
            'Authorization' = "Basic $($PatBasic)"
            'Accept'        = 'application/json'
        }       
        $Params = @{  
            Method          = 'GET' 
            Headers         = $headers
            UseBasicParsing = $true 
            ErrorAction     = 'Stop' 
            ContentType     = "application/json" 
            OutVariable     = "result" 
        }

        #$URI = 'https://dev.azure.com/{0}/_apis/distributedtask/pools' -f $Using:DevOpsOrganization
        $URI = 'https://dev.azure.com/{0}/_apis/distributedtask/pools' -f $DevOpsOrganization
        $URI += '?api-version=6.0-preview.1'
        $Body = @{
            autoProvision = $true
            name          = $PoolName
        } | ConvertTo-Json
        $Params['Method'] = 'POST'
        $Params['Body'] = $Body
        $Params['Uri'] = $URI
        $r = Invoke-WebRequest @Params -Verbose
        $out = $result[0].Content | convertfrom-json | 
            select name,id,createdOn,isHosted,poolType | ft -autosize | out-String
        Write-Verbose `n$out -verbose
        }
        #endregion set the pool
    }
            
    foreach ($agent in $DevOpsAgent.Agents)
    {
        # Windows Service Domain Credentials that the agent runs under
        $mycredp = $credlookup["$($agent.Credlookup)"].GetNetworkCredential().password
        $mycredu = $credlookup["$($agent.Credlookup)"].username
                        
        $agentName = ($agent.Name -f $Prefix,$environment)
        $poolName = ($agent.Pool -f $Prefix,$environment)
        $ServiceName = "vstsagent.$DevOpsOrganization.$poolName.$agentName"

        #$log = get-childitem -path .\_diag\ -ErrorAction Ignore | sort LastWriteTime | select -last 1

        # Region Test if the agent is running
        #$agent = $using:Agent
        # Write-Verbose -Message "Configuring service [$using:ServiceName] as [$($agent.Ensure)]" -Verbose 
        # $service = Get-Service -Name $using:ServiceName -ErrorAction Ignore -Verbose

        Write-Verbose -Message "Configuring service [$ServiceName] as [$($agent.Ensure)]" -Verbose 
        $service = Get-Service -Name $ServiceName -ErrorAction Ignore -Verbose

        if (-Not $Service)
        {
            if ($agent.Ensure -eq 'Present')
            {
                $false
                $RunFix = $true
            }
            else
            {
                $true
                $RunFix = $false
            }
        }
        else
        {
            if ($agent.Ensure -eq 'Absent')
            {
                $false
                $RunFix = $true
            }
            else
            {
                $true
                $RunFix = $false
            }
        }

        if ($RunFix)
        {
            #$agent = $using:Agent
            # Windows Service Domain Credentials
            #$DevOpsAgent = $using:DevOpsAgent
            #$credlookup = $using:credlookup
            #$AgentPath = "F:\vsagents\$($using:agentName)"
            $AgentPath = "F:\vsagents\$($agentName)"
            # PAT Token
            $mypatp = $credlookup['DevOpsPat'].GetNetworkCredential().password
            push-location
            mkdir -Path $AgentPath -EA ignore
            Set-Location -Path $AgentPath

            if (-not (Test-Path -Path .\config.cmd))
            {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                #[System.IO.Compression.ZipFile]::ExtractToDirectory($using:AgentFilePath, $PWD)
                [System.IO.Compression.ZipFile]::ExtractToDirectory($AgentFilePath, $PWD)
            }

            if ($agent.Ensure -eq 'Present')
            {
                # Write-Verbose -Message "Installing service [$using:ServiceName] setting as [$($agent.Ensure)]" -Verbose 
                # .\config.cmd --pool $using:poolName --agent $using:agentName --auth pat --token $mypatp --url $DevOpsAgent.orgUrl --acceptTeeEula `
                #     --unattended --runAsService  --windowsLogonAccount $using:mycredu --windowsLogonPassword $using:mycredp

                Write-Verbose -Message "Installing service [$ServiceName] setting as [$($agent.Ensure)]" -Verbose 
                .\config.cmd --pool $poolName --agent $agentName --auth pat --token $mypatp --url $DevOpsAgent.orgUrl --acceptTeeEula `
                    --unattended --runAsService  --windowsLogonAccount $mycredu --windowsLogonPassword $mycredp
                Pop-Location
            }
            elseif ($agent.Ensure -eq 'Absent')
            {
                # Write-Verbose -Message "Removing service [$using:ServiceName] setting as [$($agent.Ensure)]" -Verbose 
                Write-Verbose -Message "Removing service [$ServiceName] setting as [$($agent.Ensure)]" -Verbose 
                .\config.cmd remove --unattended --auth pat --token $mypatp
                Pop-Location
                Remove-Item -path $AgentPath -force -recurse
                                        
            }
        }#RunFix
    }    
}