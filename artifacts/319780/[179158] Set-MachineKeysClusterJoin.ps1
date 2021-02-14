# Run these steps on the Primary and Secondary cluster nodes
$SQLClusterNodes = 'SQL01','SQL02'

# Step 1
# set the permissions on the directory.
Invoke-Command -ComputerName $SQLClusterNodes -ScriptBlock {
Install-Module -Name NTFSSecurity
    Get-Item -Path 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys' | foreach {
    
        $_ | Set-NTFSOwner -Account BUILTIN\Administrators
        $_ | Clear-NTFSAccess -DisableInheritance
        $_ | Add-NTFSAccess -Account 'EVERYONE' -AccessRights ReadAndExecute -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account BUILTIN\Administrators -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account 'NT AUTHORITY\SYSTEM' -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Get-NTFSAccess
    }
}

# Step 2
# Then set the permissions on the individual keys
Invoke-Command -ComputerName $SQLClusterNodes -ScriptBlock {
    Install-Module -Name NTFSSecurity
    Get-ChildItem -Path 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys'  | foreach {
        Write-Verbose $_.fullname -Verbose
        $_ | Clear-NTFSAccess -DisableInheritance 
        $_ | Set-NTFSOwner -Account BUILTIN\Administrators
        $_ | Add-NTFSAccess -Account 'EVERYONE' -AccessRights ReadAndExecute -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account BUILTIN\Administrators -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Add-NTFSAccess -Account 'NT AUTHORITY\SYSTEM' -AccessRights FullControl -InheritanceFlags None -PropagationFlags NoPropagateInherit
        $_ | Get-NTFSAccess
   
    }
}

