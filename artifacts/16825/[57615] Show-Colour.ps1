function Show-Colour {

function Show-Colour {
param ([parameter(
        Position=0,
        ValueFromPipeline=$True)]
        $Background
        )

process {

    Write-Host "`nBackGround Color: $Background" -BackgroundColor $Background
    Write-Host "ForeGround Colors:"

    Foreach ($Foregroundcolor in ([enum]::getNames("Consolecolor")))
        {
            Write-Host "$foregroundcolor" -ForegroundColor $Foregroundcolor -BackgroundColor $Background
        }

    Write-Host ""

}#process

}#Show-Colour (local)

# Function code starts here . .
[enum]::GetNames("Consolecolor") | Show-Colour

}#Show-Colour



