# PowerShell Module - LocationHistory

The LocationHistory PowerShell module is based on the cd.psm1 PSCX (PowerShell community extensions) module written by Keith Hill, with some enhancements and bug fixes.

This module provides an extended `Set-Location` replacement function called `Set-LocationEx` that maintains a location history, allowing easy navigation to previous locations.

When you load this module, it sets the `cd` alias to the `Set-LocationEx` function.

The module adds the following cmdlets:

| Cmdlet                   | Description
| ------------------------ | -------------------------------------------------------
| `Clear-LocationHistory`  | Clears the location history.
| `Get-LocationHistory`    | Outputs the location history.
| `Set-LocationEx`         | Changes to a new location or a location in the history.
| `Remove-LocationHistory` | Removes a location from the location history.

After installing the module, I recommend adding the command `Import-Module LocationHistory` to your PowerShell profile so that the `cd` alias gets set automatically.

## System Requirements

Windows 8.1/Windows Server 2012 R2 or later.
