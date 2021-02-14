function Show-Desktop {

$x = New-Object -ComObject Shell.Application
$x.ToggleDesktop()

}