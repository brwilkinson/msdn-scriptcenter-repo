#requires -Module Az.Accounts
function Start-AzurePolicyEvaluation 
{
    param (
    [string]$Tenant = '1c38ce6e-6b55-4b8e-b0bb-6f6570574dd8',
    [string]$Subscription = 'd54a49ff-90d9-4fc6-8b41-018e230e8981',
    [string]$ResourceGroup,
    [int32]$SleepSeconds = 30
    )

    $CTX = Get-AzContext | where {$_.Subscription.ID -eq $Subscription -and $_.Subscription.TenantId -eq $Tenant}
    $latest = $CTX.TokenCache.ReadItems() | sort -Descending -Property ExpiresOn | select -first 1
    if ($latest.ExpiresOn -gt (get-date))
    {
        $AccessToken = $latest.AccessToken
    }
    else
    {
       Clear-AzContext -Force
       $CTX = Connect-AzAccount -Tenant $Tenant -Subscription $Subscription
       $AccessToken = $CTX.Context.TokenCache.ReadItems().AccessToken
    }

   Write-verbose $AccessToken -verbose
    
    if ($ResourceGroup)
    {
        $RESOURCEID = "/subscriptions/$Subscription/$ResourceGroup"
    }
    else
    {
        $RESOURCEID = "/subscriptions/$Subscription"
    }

    $PostURI = "https://management.azure.com/$RESOURCEID/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2018-07-01-preview"

    $Body = @{
        OutVariable     = 'Status'
        Method          = 'POST'
        UseBasicParsing = $true
        Headers         = @{
            Authorization  = "Bearer $($AccessToken)"
            'Content-Type' = 'application/json'
        }
    }

    $start = Get-Date
    Invoke-WebRequest -uri $PostURI @Body

    $Body.Method = 'Get'
    $status[0].RawContent -split "\n" | where {$_ -match "(^Location: )(?<GetURL>https://.+)"}

    while ($Status[0].StatusCode -eq 202)
    {
        sleep -Seconds $SleepSeconds
        Invoke-WebRequest -uri $Matches.GetURL @Body | select StatusCode,StatusDescription,Headers
        Write-Verbose -Message "Checking Policy in $SleepSeconds seconds"
    }
    $end = Get-Date
    [int32]$ts = New-TimeSpan -Start $Start -End $end | foreach TotalMinutes
    
    Write-Warning -Message "Policy update complete! in totalminutes: $ts"
}