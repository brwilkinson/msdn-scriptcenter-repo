param (
    [String]$clientIDGlobal = '3b81728f-d4fa-41e3-ab93-eae57a532d43',
    [String]$StorageAccountId = '/subscriptions/035342cd-b1d7-43d1-a427-c29616d201b0/resourceGroups/AZC1-ADF-RG-G1/providers/Microsoft.Storage/storageAccounts/mysastagecus1'
)


# Azure VM Metadata service
$VMMeta = Invoke-RestMethod -Headers @{"Metadata" = "true" } -URI http://169.254.169.254/metadata/instance?api-version=2019-02-01 -Method get
# $Compute = $VMMeta.compute
# $NetworkInt = $VMMeta.network.interface

# $SubscriptionId = $Compute.subscriptionId
# $ResourceGroupName = $Compute.resourceGroupName
# $Zone = $Compute.zone
# $prefix = $ResourceGroupName.split('-')[0]
# $App = $ResourceGroupName.split('-')[1]

$StorageAccountName = Split-Path -Path $StorageAccountId -Leaf

# -------- MSI (User assigned) lookup for storage account
# $Resource = 'https://management.azure.com/'
$Resource = 'https://storage.azure.com/'
$URI = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=${clientIDGlobal}&resource=${Resource}"
$response = Invoke-WebRequest -UseBasicParsing -Uri $URI -Method GET -Headers @{Metadata = "true" }
$ArmToken = $response.Content | ConvertFrom-Json | Foreach access_token

# Azure Files not supported
# $Container = 'source'
# $Type = 'file'
# $Path = 'Tools'
# $File = 'powershell.config.json'

$Container = 'azc1-stageartifacts-vssadministrator'
$Type = 'blob'
$Path = '0-archive'
$File = 'myFile.json'

$headers = @{
    'Authorization'   = "Bearer $ArmToken"
    'x-ms-date'       = $((get-date).ToUniversalTime() | get-date -UFormat "%a, %d %b %Y %T GMT")
    'x-ms-version'    = '2017-11-09'
    'Accept'          = "*/*"
    'Host'            = $('{0}.{1}.core.windows.net' -f $StorageAccountName,$Type) # Files not supported
    'accept-encoding' = 'gzip, deflate'
}

<#
    x-ms-version: 2017-11-09
    Authorization: Bearer eyJ0eXAiO...V09ccgQ
    User-Agent: PostmanRuntime/7.6.0
    Accept: */*
    Host: sampleoautheast2.blob.core.windows.net
    accept-encoding: gzip, deflate
#>

$Params = @{ 
    Method          = 'GET'
    Headers         = $headers
    UseBasicParsing = $true
    ErrorAction     = 'Stop'
    ContentType     = "application/json"
    OutVariable     = "result"
}
$Params['Uri'] = "https://{0}.{1}.core.windows.net/{2}/{3}/{4}" -f $StorageAccountName,$Type,$Container,$Path,$File
Invoke-WebRequest @Params
$result
# $result.RawContent
#?restype=service&comp=properties

