@{
  RootModule        = 'LocationHistory.psm1'
  ModuleVersion     = '1.0.8.0'
  GUID              = '1c577381-7cd2-4985-b3f0-493dcbc2b26b'
  Author            = 'Bill Stewart'
  CompanyName       = 'Bill Stewart'
  Copyright         = '(C) 2017-2024 by Bill Stewart'
  Description       = 'Set-Location replacement that maintains a location history for the current PowerShell session, allowing easy navigation between locations.'
  PowerShellVersion = '3.0'
  AliasesToExport   = '*'
  FormatsToProcess  = 'LocationHistory.format.ps1xml'
  FunctionsToExport = @(
    'Clear-LocationHistory'
    'Get-LocationHistory'
    'Set-LocationEx'
    'Remove-LocationHistory'
  )
}
