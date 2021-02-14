<#
.Synopsis
   Compare the items in the two lists that are just open in a unsaved ISE script
.DESCRIPTION
   Dot source this function into the ISE.
   
   Paste two lists into the Windows PowerShell ISE with an empty line in between.

   Compare the items in the two lists
.EXAMPLE
   
   . .\Compare-ISEList.ps1

   Open a new tab in the ISE

    abc
    def
    xyz
    Tuesday

    abc
    xyz
    klju
    Wednesday

    
    Run the function
    
    Compare-ISEList | ft -AutoSize

    Name      Items                Totalcount
    ----      -----                ----------
    Common    abc, def                      2
    FirstOnly ghi, MOnday                   2
    LasttOnly xyz, klju, Wednesday          3

#>

#Requires -Version 3.0

function Compare-ISEList {

$Lines = $psise.CurrentFile.Editor.Text -split "`n"

$Data = $lines | ForEach-Object -Begin { $i=0 } -Process { 

    [pscustomobject]@{ Line=$i;Length=$_.length;Value=$_ }
    $i++

}

$Mid = $Data | where Length | Sort-Object -Property Length,Line -Descending | 
select -Last 1 -ExpandProperty Line

$a = $Lines[0..($mid-1)]
$b = $Lines[($mid+1)..($lines.count-1)]

Compare-Object -ReferenceObject $a -DifferenceObject $b -IncludeEqual | ForEach-Object {

    if ($_.SideIndicator -eq "<=" -and $_.Inputobject.trim().length -ne 0)
        {
            [pscustomobject]@{List="FirstOnly";Value=($_.InputObject).trim()}
        }
    elseif ($_.SideIndicator -eq "=>" -and $_.Inputobject.trim().length -ne 0)
        {
            [pscustomobject]@{List="LasttOnly";Value=($_.InputObject).trim()}
        }
    elseif ($_.SideIndicator -eq "==" -and $_.Inputobject.trim().length -ne 0)
        {
            [pscustomobject]@{List="Common";Value=($_.InputObject).trim()}
        }

} | group List | sort Name | select Name,@{n="Items";e={ $_.Group.value -join ', '  }},
                                    @{n="Totalcount";e={ $_.Group.count  }}

}