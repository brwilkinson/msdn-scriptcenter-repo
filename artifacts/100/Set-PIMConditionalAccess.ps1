#requires -Modules AzureAdPreview 
#requires -PSEdition Desktop

<#
D:\Repos\scapim-ps\PIM\azureADLogin.ps1
#>

function Set-PIMConditionalAccess
{
    param (
        [validateset('Contributor', 'User Access Administrator', 'Owner', 'GrafanaViewer', 'GrafanaEditor')]
        [string]$RoleName = 'GrafanaViewer',

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$SubscriptionId = 'b8f402aa-20f7-4888-b45c-3cf086dad9c3',

        [validateset('RG', 'Sub', 'Resource')]
        [string]$Scope = 'Sub',

        [switch]$DisableConditionalAccess
    )

    process
    {
        # hard code this so don't have to lookup.
        $Role = switch ($RoleName)
        {
            'Contributor'
            {
                [pscustomobject]@{
                    Name = 'Contributor'
                    ID   = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
                }
            }
            'User Access Administrator'
            {
                [pscustomobject]@{
                    Name = 'User Access Administrator'
                    ID   = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'
                }
            }
            'Owner'
            { 
                [pscustomobject]@{
                    Name = 'Owner'
                    ID   = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' 
                } 
            }
            'GrafanaViewer'
            { 
                [pscustomobject]@{
                    Name = 'Grafana Viewer'
                    ID   = '60921a7e-fef1-4a43-9b16-a26c52ad4769' 
                } 
            }
            'GrafanaEditor'
            { 
                [pscustomobject]@{
                    Name = 'Grafana Editor'
                    ID   = 'a79a5197-3a5c-4973-a920-486035ffd60f'
                } 
            }
        }


        # Use azure resource graph to pull resource ids for different scopes.
        $Query = switch ($Scope)
        {
            'Resource' { 'Resources | project id' }
            'RG' { "ResourceContainers | where type == 'microsoft.resources/subscriptions/resourcegroups' | project id" }
            'Sub' { "ResourceContainers | where type == 'microsoft.resources/subscriptions' | project id" }
        }
        $all = Search-AzGraph -Query $Query -Subscription $SubscriptionId -First 1000
    
        # resource graph queries have a limit of 1000, could hit resource limits in a subscription.
        if ($all.count -ge 1000)
        { Write-Warning "[$Scope] Too many resources [$($all.count)]!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" }
        else
        { Write-Warning "[$Scope] resources found [$($all.count)]" }
    
        # loop through all items at scope, to find the PIM ResourceId
        # should just be 1 subscription
        $all | ForEach-Object {
            $PIMID = $_.id

            try
            {
                $ResourcePIM = Get-AzureADMSPrivilegedResource -ProviderId 'AzureResources' -Filter "ExternalId eq '$PIMID'" -ErrorAction stop
                $ResourcePIM | ForEach-Object {
        
                    $ResourceId = $_.Id
                    Write-Warning "Resource PIM id        : $ResourceId"

                    $Filter = "ExternalId eq '/subscriptions/$subscriptionID/providers/Microsoft.Authorization/roleDefinitions/$($Role.ID)'"
                    $RoleDefinitionPIM = Get-AzureADMSPrivilegedRoleDefinition -ProviderId 'AzureResources' -Filter $Filter -ResourceId $ResourceId

                    # Find the Role setting on the Subscription
                    $Filter = "ResourceId eq '$ResourceId' and RoleDefinitionId eq '$($RoleDefinitionPIM.Id)'"

                    $current = Get-AzureADMSPrivilegedRoleSetting -ProviderId AzureResources -Filter $Filter

                    $AcrsRule = $current.UserMemberSettings | Where-Object RuleIdentifier -EQ AcrsRule
                    $currentacrsRequired = $AcrsRule.Setting | ConvertFrom-Json | ForEach-Object acrsRequired

                    $acrsRequired = 'true'
                    if ($DisableConditionalAccess) { $acrsRequired = 'false' }
            
                    if ( $acrsRequired -ne $currentacrsRequired )
                    {
                        $AcrsRule.Setting = switch ($acrsRequired)
                        {
                            'false' { '{"acrs":"urn:microsoft:req1","acrsRequired":false}' }
                            'true' { '{"acrs":"urn:microsoft:req1","acrsRequired":true}' }
                        }
            
                        Write-Warning -Message "Updating Role [$($RoleDefinitionPIM.DisplayName)]"
                        Write-Warning -Message "Updating ACRS [$($AcrsRule.Setting)]"

                        $RoleSettings = @{
                            ProviderId         = 'AzureResources'
                            RoleDefinitionId   = $RoleDefinitionPIM.Id
                            ResourceId         = $ResourceId 
                            Id                 = $current.Id
                            UserMemberSettings = $AcrsRule
                        }
                        Set-AzureADMSPrivilegedRoleSetting @RoleSettings
                    }
                    else
                    {
                        $AcrsRule
                    }
                }
            }
            Catch
            {
                Write-Warning "PIM not enabled on this resources id [$PIMID]"
                Write-Warning $_.Exception
            }
        }
    }#Process
}#Set-PIMConditionalAccess