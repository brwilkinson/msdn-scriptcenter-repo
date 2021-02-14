<#
.Synopsis
   Find AzureRM Publishers, Offers and SKu's of Gallery Images
.DESCRIPTION
   Find AzureRM Publishers, Offers and SKu's of Gallery Images, this is required when deploying Virtual Machine Images, 
   It is recommended to use the 'Latest' for the version, instead of a specific version
.EXAMPLE
    Find-AzureRMPublisherImageOffer -Location EASTUS2
.EXAMPLE
    Find-AzureRMPublisherImageOffer -Location EASTUS2 -Publisher MicrosoftWindowsServer -OfferName WindowsServer

    WARNING: It is recommended to use the 'Latest' for the version, instead of a specific version
    Version           PublisherName          Offer         Skus           
    -------           -------------          -----         ----           
    2016.127.20170406 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20170421 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20170510 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20170630 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20170712 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20170822 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20170918 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20171017 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20171116 MicrosoftWindowsServer WindowsServer 2016-Datacenter
    2016.127.20171217 MicrosoftWindowsServer WindowsServer 2016-Datacenter
.EXAMPLE
    Find-AzureRMPublisherImageOffer -Location EASTUS2 -Publisher cloudbees-enterprise-jenkins -OfferName cloudbees-jenkins-enterprise

    WARNING: It is recommended to use the 'Latest' for the version, instead of a specific version
    Version     PublisherName                Offer                        Skus                              
    -------     -------------                -----                        ----                              
    15.05.02001 cloudbees-enterprise-jenkins cloudbees-jenkins-enterprise cloudbees-jenkins-enterprise-14-11
    15.05.02002 cloudbees-enterprise-jenkins cloudbees-jenkins-enterprise cloudbees-jenkins-enterprise-14-11
    15.05.02003 cloudbees-enterprise-jenkins cloudbees-jenkins-enterprise cloudbees-jenkins-enterprise-14-11
    15.11.02001 cloudbees-enterprise-jenkins cloudbees-jenkins-enterprise cloudbees-jenkins-enterprise-14-11
    15.11.02002 cloudbees-enterprise-jenkins cloudbees-jenkins-enterprise cloudbees-jenkins-enterprise-14-11
.EXAMPLE
    Find-AzureRMPublisherImageOffer -Location EASTUS2 -Publisher RedHat -OfferName RHEL

    WARNING: It is recommended to use the 'Latest' for the version, instead of a specific version
    Version        PublisherName Offer Skus
    -------        ------------- ----- ----
    7.3.20161104   RedHat        RHEL  7.3 
    7.3.20170201   RedHat        RHEL  7.3 
    7.3.20170223   RedHat        RHEL  7.3 
    7.3.2017032021 RedHat        RHEL  7.3 
    7.3.2017042521 RedHat        RHEL  7.3 
    7.3.2017051117 RedHat        RHEL  7.3 
    7.3.2017052619 RedHat        RHEL  7.3 
    7.3.2017053019 RedHat        RHEL  7.3 
    7.3.2017062722 RedHat        RHEL  7.3 
    7.3.2017071923 RedHat        RHEL  7.3 
    7.3.2017081103 RedHat        RHEL  7.3 
    7.3.2017081120 RedHat        RHEL  7.3 
    7.3.2017090105 RedHat        RHEL  7.3 
    7.3.2017090723 RedHat        RHEL  7.3 
#>

Function Find-AzureRMPublisherImageOffer {

param (
   # Virtual Machine offerings are dependent on the region they are deployed
   $Location,
   
   $Publisher,
   
   $OfferName,
   
   $Sku 
)

    Write-Verbose -Message "Searching for VM Sizes in region: $Location"
try {
    if (! $Location)
    {
        $Location = Get-AzureRmLocation | Out-GridView -OutputMode Single -Title "Select the Location you want to deploy? Then click OK." | Foreach Location
    }
    if (! $Publisher)
    {
        $Publisher = Get-AzureRMVMImagePublisher -Location $Location -EA Stop | Select -Property PublisherName,Location |
            Out-GridView -OutputMode Single -Title "Select the Publisher for your Image? Then click OK." | Foreach PublisherName
    }
    if (! $OfferName)
    {
        $OfferName = Get-AzureRMVMImageOffer -Location $location -Publisher $Publisher -EA Stop | Out-GridView -OutputMode Single -Title "Select the OfferName for your Image? Then click OK." | Foreach Offer
    }
    if (! $Sku)
    {
        $Sku = Get-AzureRMVMImageSku -Location $location -Publisher $Publisher -Offer $offerName -EA Stop | Select -pro Skus,Offer,PublisherName,Location |
            Out-GridView -OutputMode Single -Title "Select the Skus for your Image? Then click OK." | Foreach Skus
    }

    Get-AzureRmVMImage -Location $Location -PublisherName $Publisher -Offer $offerName -Skus $SKU -EA Stop | 
        Select Version,PublisherName,Offer,Skus

    Write-Warning -Message "It is recommended to use the 'Latest' for the version, instead of a specific version"
   }
   Catch {
    Switch -Regex ( $_ )
    {
        'Offer'   {Write-Warning -Message "Publisher '$Publisher' does not exist"}
        'Sku'     {Write-Warning -Message "OfferName '$offerName' does not exist"}
        'VMImage' {Write-Warning -Message "Sku '$Sku' does not exist"}
        'Default' {Write-Warning -Message $_}
    }
   }
}