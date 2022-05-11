
#requires -Modules AzureAdPreview, Az.ResourceGraph
#requires -PSEdition Desktop

<#
D:\Repos\scapim-ps\PIM\azureADLogin.ps1
#>

function Update-PIMRoleAssignment
{
    param (
        [Parameter(Mandatory)]
        $SubscriptionId,

        [Parameter(Mandatory)]
        $resourceid,
    
        [Parameter(Mandatory)]
        [validateset('Contributor', 'User Access Administrator', 'Owner', 'GrafanaViewer', 'GrafanaEditor', 'Security Admin', 'Reader')]
        [string]$RoleName,

        [Parameter(Mandatory)]
        [string]$subjectId,

        [int]$durationdays = 180,
        [switch]$Remove
    )

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
        'Reader'
        { 
            [pscustomobject]@{
                Name = 'Grafana Viewer'
                ID   = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
            }
        }
        'Security Admin'
        { 
            [pscustomobject]@{
                Name = 'Security Admin'
                ID   = 'fb1c8493-542b-48eb-b624-b4c8fea62acd'
            }
        }
    }

    $Scope = if (($resourceid -split '/' | Measure-Object | ForEach-Object Count) -le 5) { 'ResourceContainers' }else { 'Resources' }
    $Query = "$Scope | where id == '$Resourceid'"

    $pimresource = Search-AzGraph -Query $Query -Subscription $SubscriptionId

    try
    {
        $ResourcePIM = Get-AzureADMSPrivilegedResource -ProviderId 'AzureResources' -Filter "ExternalId eq '$($pimresource.id)'" -ErrorAction stop

        $Filter = "ExternalId eq '/subscriptions/$subscriptionID/providers/Microsoft.Authorization/roleDefinitions/$($Role.ID)'"
        $RoleDefinitionPIM = Get-AzureADMSPrivilegedRoleDefinition -ProviderId 'AzureResources' -Filter $Filter -ResourceId $ResourcePIM.Id

        # Find all of the assignments for the role at that pim resourceid scope.
        $Filter = "membertype ne 'Inherited' and RoleDefinitionId eq '$($RoleDefinitionPIM.Id)' and SubjectId eq '$subjectId'"
        $current = Get-AzureADMSPrivilegedRoleAssignment -ProviderId 'AzureResources' -ResourceId $ResourcePIM.id -Filter $Filter

        $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
        $schedule.Type = 'Once'
        $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        $schedule.EndDateTime = ((Get-Date).AddDays($durationdays)).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

        $Request = @{
            ProviderId       = 'AzureResources'
            Schedule         = $schedule
            ResourceId       = $ResourcePIM.id
            RoleDefinitionId = $RoleDefinitionPIM.Id
            SubjectId        = $subjectId
            AssignmentState  = 'Eligible'
        }

        if ($current)
        {
            $current

            if ($Remove)
            {
                Write-Output "Will remove          subscription: [$SubscriptionId] Role: [$Rolename] SubjectId: [$subjectId] ${Scope}: [$resourceid]"
                Open-AzureADMSPrivilegedRoleAssignmentRequest @Request -Type 'AdminRemove'
            }
            else 
            {
                Write-Warning -Message "Assignment exists    subscription: [$SubscriptionId] Role: [$Rolename] SubjectId: [$subjectId] ${Scope}: [$resourceid]"
            }
        }
        else
        {
            if ($Remove)
            {
                Write-Warning -Message "Assignment not found subscription: [$SubscriptionId] Role: [$Rolename] SubjectId: [$subjectId] ${Scope}: [$resourceid]"
            }
            else
            {
                Write-Output "Adding assignment    subscription: [$SubscriptionId] Role: [$Rolename] SubjectId: [$subjectId] ${Scope}: [$resourceid]"
                Open-AzureADMSPrivilegedRoleAssignmentRequest @Request -Type 'AdminUpdate' #'AdminAdd'
            }
        }
    }
    Catch
    {
        Write-Warning "PIM not enabled on this resources id [$PIMID]"
        Write-Warning $_.Exception
    }
}#Update-PIMRoleAssignment