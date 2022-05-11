
#requires -Modules AzureAdPreview, Az.ResourceGraph
#requires -PSEdition Desktop

<#
D:\Repos\scapim-ps\PIM\azureADLogin.ps1
#>

function Start-PIMRoleAssignment
{
    param (
        # [Parameter(Mandatory)]
        $SubscriptionId = 'd1f3e085-e43c-4c1b-853d-4c7c9d11971f',

        # [Parameter(Mandatory)]
        [validateset('/subscriptions/d1f3e085-e43c-4c1b-853d-4c7c9d11971f','/providers/Microsoft.Management/managementGroups/da8adb85-fac3-495b-b233-539f05dd6354')]
        $resourceid = '/providers/Microsoft.Management/managementGroups/da8adb85-fac3-495b-b233-539f05dd6354',
    
        # [Parameter(Mandatory)]
        [validateset('Contributor', 'User Access Administrator', 'Owner', 'GrafanaViewer', 'GrafanaEditor', 'Security Admin', 'Reader')]
        [string]$RoleName = 'Reader',

        # [Parameter(Mandatory)]
        [string]$subjectId = 'a5251dd2-8a7b-41e4-b5e1-fbebce477233',

        [int]$durationhours = 8,

        [string]$Reason = 'azts',

        [switch]$Renew
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

    $pimresource = Search-AzGraph -Query $Query -ManagementGroup e1ee3852-b508-491b-8f1c-04c7e42687f6

    try
    {
        $ResourcePIM = Get-AzureADMSPrivilegedResource -ProviderId 'AzureResources' -Filter "ExternalId eq '$($pimresource.id)'" -ErrorAction stop

        $Filter = "ExternalId eq '/providers/Microsoft.Authorization/roleDefinitions/$($Role.ID)'"
        $RoleDefinitionPIM = Get-AzureADMSPrivilegedRoleDefinition -ProviderId 'AzureResources' -ResourceId $ResourcePIM.Id -Filter $Filter 

        # Find all of the assignments for the role at that pim resourceid scope.
        $Filter = "membertype ne 'Inherited' and RoleDefinitionId eq '$($RoleDefinitionPIM.Id)' and SubjectId eq '$subjectId'"
        $current = Get-AzureADMSPrivilegedRoleAssignment -ProviderId 'AzureResources' -ResourceId $ResourcePIM.id -Filter $Filter

        if ((-not $Renew) -and ($current | Where-Object AssignmentState -EQ Active))
        {
            $Active = $current | Where-Object AssignmentState -EQ Active
            # $start = ($Active.StartDateTime).ToLocalTime()
            $end = ($Active.EndDateTime).ToLocalTime()
            $remaininghours = New-TimeSpan -Start (Get-Date) -End $End | ForEach-Object TotalHours
            Write-Warning -Message "PIM is Active for [$RoleName] for the next [$remaininghours] hours"
        }
        else
        {
            $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
            $schedule.Type = 'Once'
            $schedule.StartDateTime = (Get-Date).ToUniversalTime()
            $schedule.EndDateTime = $schedule.StartDateTime.AddHours($durationhours)

            $Request = @{
                ProviderId       = 'AzureResources'
                Schedule         = $schedule
                ResourceId       = $ResourcePIM.id
                RoleDefinitionId = $RoleDefinitionPIM.Id
                SubjectId        = $subjectId
                AssignmentState  = 'Active'
                Reason           = $Reason
            }

            if ($ReNew)
            {
                Write-Warning -Message "Will Renew Assignment for Role: [$Rolename] SubjectId: [$subjectId] ${Scope}: [$resourceid]"
                Open-AzureADMSPrivilegedRoleAssignmentRequest @Request -Type UserRemove
                Write-Warning -Message "Removing, plese wait ..."
                Start-Sleep -Seconds 30
            }

            Write-Warning -Message "Will Add Assignment for Role: [$SubscriptionId] Role: [$Rolename] SubjectId: [$subjectId] ${Scope}: [$resourceid]"
            Open-AzureADMSPrivilegedRoleAssignmentRequest @Request -Type UserAdd
        }
    }
    Catch
    {
        Write-Warning "PIM not enabled on this resources id [$($ResourcePIM.Id)]"
        Write-Warning $_.Exception
    }
}#Update-PIMRoleAssignment
New-Alias -Name startpim -Value Start-PIMRoleAssignment