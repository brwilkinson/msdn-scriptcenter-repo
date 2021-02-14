function azl
{
    param(
        [validateset('Personal','Work','MSDN','PROD','PREPROD')]
        [String]$Account,
        [Switch]$auth
    )

    $AZ = Switch ($Account)
    {
        'Personal'
        {
            @{ 
                Name     = "Personal Subscription"
                Id       = "3e1bedb1-4ec9-4491-8dd7-ba347be1097d"
                TenantId = "e078d341-64b8-4729-8614-e62c5f7916db"
                State    = "Enabled"
            }
        }
        'Work'
        {
            @{ 
                Name     = "Work Subscription"
                Id       = "3e1bedb1-4ec9-4491-8dd7-ba347be1097d"
                TenantId = "e078d341-64b8-4729-8614-e62c5f7916db"
                State    = "Enabled"
            }
        }
        'MSDN'
        {
            @{ 
                Name     = "MSDN Subscription"
                Id       = "3e1bedb1-4ec9-4491-8dd7-ba347be1097d"
                TenantId = "e078d341-64b8-4729-8614-e62c5f7916db"
                State    = "Enabled"
            }
        }
        'PROD'
        {
            @{ 
                Name     = "PROD Subscription"
                Id       = "3e1bedb1-4ec9-4491-8dd7-ba347be1097d"
                TenantId = "e078d341-64b8-4729-8614-e62c5f7916db"
                State    = "Enabled"
            }
        }
        'PREPROD'
        {
            @{ 
                Name     = "PREPROD Subscription"
                Id       = "3e1bedb1-4ec9-4491-8dd7-ba347be1097d"
                TenantId = "e078d341-64b8-4729-8614-e62c5f7916db"
                State    = "Enabled"
            }
        }
    }

    if ($Account)
    {
        if ($auth)
        {
            Add-AzAccount -TenantId $AZ.TenantId -SubscriptionId $AZ.ID
        }
        else
        {
            Select-AzSubscription -SubscriptionId $AZ.ID
        }
    }
    else
    {
        Get-AzContext
    }
}