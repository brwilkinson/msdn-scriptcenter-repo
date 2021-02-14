#Requires -Version 3.0
function Measure-MyCommand {
param (
        [ScriptBlock]$ScriptBlock,
        [Int32]$Iterations = 10,
        [ValidateSet("TotalMilliSeconds", "TotalSeconds", "TotalMinutes")]
        [String]$TimeSpanScale = "TotalMilliseconds"
        )
Begin {
        [Int32]$TimeSpan=0
}#Begin
Process {
        $Result = foreach ($i in 1..$Iterations)
        {
            $a = {Measure-Command -Expression $Scriptblock | Select $TimeSpanScale}
            Invoke-Command -ScriptBlock $a -ArgumentList $Scriptblock
           
            if ($i % 800)
            {
                if ($i % 10)
                {
                    # Do nothing
                }
                else
                {
                    Write-Host "." -NoNewline
                }
            }
            else
            {
                Write-Host "."
            }
            
        }

        #$Result

}#Process
End {
    
     Write-Host "."
     $Sum = $Result."$TimeSpanScale" | Measure-Object -Sum | Select -ExpandProperty Sum     
     [pscustomobject]@{"AverageCommandTime"=([System.Math]::Round($Sum/$Iterations,3))}
     
}#end

}