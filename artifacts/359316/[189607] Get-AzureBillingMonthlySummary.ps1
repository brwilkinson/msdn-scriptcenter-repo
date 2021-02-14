#Requires -Module AzureRM.Profile,AzureRM.Resources,AzureRM.Billing
#Requires -version 3.0

# Get price sheet and usage details for the current period.
# https://docs.microsoft.com/en-us/azure/billing/billing-enterprise-api

# Main link on JSON Paged queries (Asynchronous)
# https://docs.microsoft.com/en-us/rest/api/billing/enterprise/billing-enterprise-api-usage-detail#json-format
# The maximum supported time range is 36 months

function Get-AzureBillingUsageDetails
{
[cmdletbinding()]
    param (
        [parameter(mandatory)]
        [string]$enrollmentNo,

        [parameter(mandatory)]
        [string]$accessKey
    )
    
    try {    
    
    Write-Verbose -Message "Checking Billing Period for the following Context:" -Verbose

    Write-Warning -Message "Please select Billing Period from pop up."

    $BillingPeriod = Get-AzureRmBillingPeriod | Where {$_.BillingPeriodEndDate -gt (Get-Date)} |
                        Select -Property Name,BillingPeriodStartDate,BillingPeriodEndDate |
                        Out-GridView -Title "Please select the billing period" -OutputMode Single |
                        Foreach Name 

    $authHeaders = @{"authorization"="bearer $accessKey"}
    $usageUrl = "https://consumption.azure.com/v2/enrollments/$enrollmentNo/billingPeriods/$BillingPeriod/usagedetails"

    Write-Verbose -Message "URL: $usageUrl" -Verbose
    Write-Verbose -Message "Selected Month, Billing Period: $BillingPeriod" -Verbose
    Write-Verbose -Message "Polling for Data, please wait..." -Verbose

        while ($usageUrl -ne $null) #1000 lines of usage data returned per request
        {
            $usagedetails = Invoke-RestMethod -Uri $usageUrl -Headers $authHeaders -ErrorAction Stop -Method GET
            $usagedetails.data
            $usageUrl = $usagedetails.nextLink
        }
    Write-Verbose -Message "Completed Polling for Data" -Verbose
    }
    Catch {
        Write-Warning $_
    }
}#Get-AzureBillUsageDetails

function Get-AzureBillingMonthlySummary
{
 param (
        $usage,
        $Filter = '.'
    )

    end{
        [double]$gtotal = 0
        $usage | group resourcegroup | sort Name -Descending | 
        Where Name -match $Filter |
        foreach-object {

        $g = $_.group
        $total = ($g | measure -Property cost -Sum | foreach Sum)

            [pscustomobject]@{
                CostCenter       = $g[0].costcenter
                SubscriptionName = $g[0].subscriptionName
                ResourceGroup    = $g[0].resourceGroup
                AccountName      = $g[0].accountName
                AccountOwnerEmail= $g[0].accountOwnerEmail
                DepartmentId     = $g[0].departmentId
                TotalCost        = "{0:C}" -f $total
        }

            $gtotal += $total
        }#Foreach-Object
    Write-Verbose "Total is: $gtotal" -Verbose
    }#End
}#Get-AzureBillingMonthlySummary

break

Login-AzureRmAccount
Get-AzureRmContext
Get-AzureRmSubscription

<# Input (CSV Format)

Subscription,EnrollmentNo,AccessKey
API-PRODUCTION-APP,123456,asdfqwerlkjhpoiu12sd3456
#>

Import-Csv -Path D:\azure\billing.csv | foreach-object {

    Select-AzureRmSubscription -Subscription $_.Subscription
    $usage = Get-AzureBillingUsageDetails -AccessKey $_.AccessKey -EnrollmentNo $_.EnrollmentNo
    $Report = Get-AzureBillingMonthlySummary -usage $usage -filter P6
    $Report

}

<# Output

CostCenter        : 123456
subscriptionName  : API-PRODUCTION-APP
resourcegroup     : AZE2-P6-API
accountName       : Jennifer Holland
accountOwnerEmail : jennifer.holland@contoso.com
departmentId      : 54327
TotalCost         : $5,094.68
#>

# Full list of fields are available here:
# https://docs.microsoft.com/en-us/rest/api/billing/enterprise/billing-enterprise-api-usage-detail#usage-details-field-definitions