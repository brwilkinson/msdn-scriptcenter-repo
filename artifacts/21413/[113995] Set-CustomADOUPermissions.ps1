<#
.Synopsis
   Sets the Permission for a AD Security Group to Create and Delete Computer Objects from a particular Container in AD.
.DESCRIPTION
   Sets the Permission for an active AD Security Group to Create and Delete Computer Objects from a particular Container that is specified as a parameter to the Script. 
   The script requires PowerShell version 2.0 and the ActiveDirectory Module, which is available on Windows 7 or Server 2008 R2 or later Computers.
   On Windows 7/8 machines the ActiveDirectory Module is part of the RSAT. One server OS the module and RSAT are features you can add.
   The Administrator running the script will require the correct permission to write to ACL Changes to the Organizational Units in ActiveDirectory.

.EXAMPLE
   Set the custom permission to the LabAdmins Group on a given Organizational Unit Lab100.
   Set-CustomADOUPermissions -DistinguishedName "OU=Lab100,OU=LabComputers,OU=Test,DC=DevDomain,DC=com" -AdminGroup "LabAdmins"
.EXAMPLE
    Query the list of Organizational Units with the names like LabComputers* and then extract the DistinguishedNames, used to set the custom permissions.
    Import-Module -Name ActiveDirectory
    $ComputerAdmins = "Role-LabCompAdmins"
    $DistinguishedName = Get-ADOrganizationalUnit -Filter {Name -like 'LabComputers*'} | Select-Object -ExpandProperty DistinguishedName
    Set-CustomADOUPermissions -DistinguishedName $DistinguishedName -AdminGroup $ComputerAdmins
.EXAMPLE
    If you use a custom mapped ActiveDirectory PSDrive than the default when loading the ActiveDirectory Module, then you can specify the ADDrive Name.
    New-PSDrive -Name DEVAD -PSProvider ActiveDirectory -Root //RootDSE/ -Server 10.1.10.1 -Credential (Get-Credential -Credential DEVAD\Administrator)
    Set-CustomADOUPermissions -ADDrive DEVAD: -DistinguishedName "OU=Lab100,OU=LabComputers,OU=Test,DC=DevDomain,DC=com" -AdminGroup "LabAdmins"
.INPUTS
   The script requires the DistinguishedName of the OrganizationalUnit that the ACL will be applied.
   The script requires the Name of of the group in one of the following formats:
    [Distinguished Name, GUID (objectGUID), Security Identifier (objectSid), SAM Account Name (sAMAccountName)]
.OUTPUTS
   The output will be the new/update ACL object [System.DirectoryServices.ActiveDirectorySecurity]
.NOTES
    This script creates and adds the following [System.DirectoryServices.ActiveDirectoryAccessRule] objects to the ACL.
    http://msdn.microsoft.com/en-us/library/system.directoryservices.activedirectoryaccessrule.aspx

    ActiveDirectoryRights : ReadProperty, WriteProperty, GenericExecute
    InheritanceType       : All
    ObjectType            : 00000000-0000-0000-0000-000000000000
    InheritedObjectType   : 00000000-0000-0000-0000-000000000000
    ObjectFlags           : None
    AccessControlType     : Allow
    IdentityReference     : S-1-5-21-600458964-1546661302-1048826702-1181
    IsInherited           : False
    InheritanceFlags      : ContainerInherit
    PropagationFlags      : None

    ActiveDirectoryRights : CreateChild, DeleteChild
    InheritanceType       : All
    ObjectType            : bf967a86-0de6-11d0-a285-00aa003049e2
    InheritedObjectType   : 00000000-0000-0000-0000-000000000000
    ObjectFlags           : ObjectAceTypePresent
    AccessControlType     : Allow
    IdentityReference     : S-1-5-21-600458964-1546661302-1048826702-1181
    IsInherited           : False
    InheritanceFlags      : ContainerInherit
    PropagationFlags      : None

    If you duplicate and modify the script you can reference the following links to create your own custom permission sets.
    http://msdn.microsoft.com/en-us/library/sskw937h.aspx
        --> Parameters
        identity
            Type: System.Security.Principal.IdentityReference
            An IdentityReference object that identifies the trustee of the access rule.
            http://msdn.microsoft.com/en-us/library/system.security.principal.identityreference.aspx

        adRights
            Type: System.DirectoryServices.ActiveDirectoryRights
            A combination of one or more of the ActiveDirectoryRights enumeration values that specifies the rights of the access rule.
            http://msdn.microsoft.com/en-us/library/system.directoryservices.activedirectoryrights.aspx
        
        type
            Type: System.Security.AccessControl.AccessControlType
            One of the AccessControlType enumeration values that specifies the access rule type.
            http://msdn.microsoft.com/en-us/library/w4ds5h86.aspx

        object
            TypeType: System.Guid
            The schema GUID of the object to which the access rule applies.
            http://msdn.microsoft.com/en-us/library/system.guid.aspx
.FUNCTIONALITY
   Automate the settings of permission on ActiveDirectory OrganizationalUnits.
#>
#Require -Version 2.0 -Modules ActiveDirectory

function Set-CustomADOUPermissions {

    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([System.DirectoryServices.ActiveDirectorySecurity])]
    Param (
           [Parameter(Mandatory=$true, 
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true)]
           [String[]]$DistinguishedName,
           [parameter(Mandatory=$true)]
           [String]$AdminGroup,
           [String]$ADDrive = 'AD:'
           )

begin {
        # Load the required Module
        Import-Module -Name ActiveDirectory -ErrorAction SilentlyContinue

        # Test if the ActiveDirectory Module is loaded, or else Exit
        try {
            Get-Module -Name ActiveDirectory -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Verbose -Message 'You need the ActiveDirectory Module to run this script, now exiting.' -Verbose
            break
        }

        # The AD drive must be connected to proceed, use "Get-PSDrive -PSProvider ActiveDirectory" to test.
        try {
            Test-Path $ADDrive -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Verbose -Message 'You need connect to the AD: drive, now exiting.' -Verbose
            break
        }

        # Confirm the correct Group name has been provided
        try {
            $GroupSID = Get-ADGroup -Identity $AdminGroup -ErrorAction Stop | Select-Object -ExpandProperty SID
        }
        catch {
            Write-Verbose -Message "Cannot find group: $AdminGroup, please supply the correct group name, now exiting." -Verbose
            break
        }

    }#begin

Process {

    # Process each DistinguishedName to add the new permissions

    $DistinguishedName | ForEach-Object {

        try {
                # Get the OU
                $Container = Get-ADObject -Identity $_ -ErrorAction Stop
                $ContainerPath = $ADDrive + '\' + $Container.DistinguishedName
            }
        catch
            {
                Write-Verbose -Message "Cannot find the OU: $_" -Verbose
                break
            }
            
        try {
                # Get the Current ACL
                $ACL = Get-Acl -Path $ContainerPath
            }
        catch
            {
                Write-Verbose -Message "Cannot read permission on the OU: $($Container.Name)" -Verbose 
                break
            }
        
        #SchemaIDGuid for the Computer Class: bf967a86-0de6-11d0-a285-00aa003049e2
        $ObjectGUID = New-Object -TypeName GUID -ArgumentList bf967a86-0de6-11d0-a285-00aa003049e2                         

        # First Access Rule (ReadProperty, WriteProperty, GenericExecute)
        $Arguments1 = $GroupSID,'ReadProperty,WriteProperty,GenericExecute','Allow',$ObjectGUID
        $R_W_E = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList $Arguments1
        
        # Second Access Rule (CreateChild, DeleteChild)
        $Arguments2 = $GroupSID,'CreateChild, DeleteChild','Allow',$ObjectGUID
        $Create_Del_Comp = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList $Arguments2
        
        # Add the new AccessRules to the current ACL
        $ACL.AddAccessRule($R_W_E)
        $ACL.AddAccessRule($Create_Del_Comp)
        
        try {
                if ($pscmdlet.ShouldProcess($OUPath, "Adding Permissions`"" + $($R_W_E, $Create_Del_Comp | Out-String) + "`"To Organizational Unit:"))
                   {
                        # Write the ACL to the OU
                        Write-Host ''
                        Set-Acl -Path $ContainerPath -AclObject $ACL -Passthru -Verbose
                   }
            }
        catch {
                Write-Verbose -Message 'Unable to apply the Permission to the Organizational Unit!!!' -Verbose
                Write-Verbose -Message 'You may not have the required permissions!!' -Verbose
            }

}#Foreach-object(Container-DistinguishedName)
}#Process
}#Set-CustomADOUPermissions