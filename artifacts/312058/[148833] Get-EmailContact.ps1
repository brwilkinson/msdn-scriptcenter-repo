function Get-EmailContact {
  Param (
    [String[]]$result = " <John.Hall@contoso.com>; Jones, Jamoe <Jamie.Jones@contoso.com>; Ralphe, Sarah <Sarah.Ralphe@contoso.com>; Thames, Aaron <Aaron.Thames@contoso.com>; Burows, Michaele <Michaele.Burows@contoso.com>"
  )
  
  
  $result -split ";" | foreach {
    
    $Name,$Email = $_.trimend(">") -split " <"
    $hash = @{
        Name  = $Name.trim()
        Email = $Email.trim()


    }
    New-Object -TypeName psobject -Property $hash | Select Name,Email
  }
  
}