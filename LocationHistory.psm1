#------------------------------------------------------------------------------
# LocationHistory.psm1
#
# (C) 2017-2024 by by Bill Stewart (bstewart AT iname.com)
# Special thanks to Keith Hill (cd.psm1 from PSCX)
#
# This module is based on Keith Hill's cd.psm1 module in the PowerShell
# Community Extensions (PSCX) package, with some behavioral changes, fixes,
# additions, and extensions.
#
# The location history stores up to 100 locations (IDs 0-99) and does not
# persist beyond the current PowerShell session.
#
# Exported functions:
#
# * Set-LocationEx is a Set-Location replacement that uses a location history.
# * Get-LocationHistory outputs the location history.
# * Clear-LocationHistory clears the location history.
# * Remove-LocationHistory removes a location from the location history.
#------------------------------------------------------------------------------

#requires -version 3

# Remember no more than this many locations.
$MAX_HISTORY_SIZE = 100

# So we can copy to the clipboard.
Add-Type -AssemblyName System.Windows.Forms

# Module-level global variables store the location stacks
$BackwardStack = New-Object Collections.Generic.List[String]
$ForwardStack = New-Object Collections.Generic.List[String]

# Clears the location history
function Clear-LocationHistory {
  <#
  .SYNOPSIS
  Clears the location history.

  .DESCRIPTION
  Clears the location history. The location history contains a list of locations visited in the current PowerShell session.
  #>
  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
  param()
  if ( $PSCmdlet.ShouldProcess("Location history","Clear") ) {
    $ForwardStack.Clear()
    $BackwardStack.Clear()
  }
}

# Outputs the location history
function Get-LocationHistory {
  <#
  .SYNOPSIS
  Outputs the location history.

  .DESCRIPTION
  Outputs the location history. The location history contains a list of locations visited in the current PowerShell session.
  #>
  if ( $BackwardStack.Count -ge 0 ) {
    for ( $i = 0; $i -lt $BackwardStack.Count; $i++ ) {
      $outputObject = [PSCustomObject] @{
        "Current"  = $null
        "Id"       = $i
        "Location" = $BackwardStack[$i]
      }
      $outputObject.PSObject.TypeNames.Insert(0,"System.Management.Automation.PSCustomObject.LocationHistoryObject")
      $outputObject
    }
  }
  $ndx = $BackwardStack.Count
  $outputObject = [PSCustomObject] @{
    "Current"  = "=>"
    "Id"       = $ndx
    "Location" = $ExecutionContext.SessionState.Path.CurrentLocation.Path
  }
  $outputObject.PSObject.TypeNames.Insert(0,"System.Management.Automation.PSCustomObject.LocationHistoryObject")
  $outputObject
  if ( $ForwardStack.Count -ge 0 ) {
    $ndx++
    for ( $i = 0; $i -lt $ForwardStack.Count; $i++ ) {
      $outputObject = [PSCustomObject] @{
        "Current"  = $null
        "Id"       = $ndx + $i
        "Location" = $ForwardStack[$i]
      }
      $outputObject.PSObject.TypeNames.Insert(0,"System.Management.Automation.PSCustomObject.LocationHistoryObject")
      $outputObject
    }
  }
}

# Removes a location from the location history.
function Remove-LocationHistory {
  <#
  .SYNOPSIS
  Removes a location from the location history.

  .DESCRIPTION
  Removes a location from the location history. This is useful when a location in the location history is no longer valid (e.g., a location that has been renamed or removed).

  .PARAMETER Id
  Removes the specified location from the location history.

  .EXAMPLE
  PS C:\> Remove-LocationHistory 3
  Removes location Id 3 from the location history.
  #>
  [CmdletBinding(DefaultParameterSetName = "Path")]
  param(
    [Parameter(Mandatory)]
    [Int]
    $Id
  )
  if ( ($Id -lt 0) -or ($Id -gt $MAX_HISTORY_SIZE - 1) ) {
    Write-Warning ("Id must be between 0 and {0}." -f ($MAX_HISTORY_SIZE - 1))
    return
  }
  if ( $Id -eq $BackwardStack.Count ) {
    Write-Warning "Cannot remove the current location from the location history."
    return
  }
  if ( $Id -lt $BackwardStack.Count ) {
    $BackwardStack.RemoveAt($Id)
  }
  elseif ( ($Id -gt $BackwardStack.Count) -and ($Id -lt $BackwardStack.Count + 1 + $ForwardStack.Count) ) {
    $ndx = $Id - ($BackwardStack.Count + 1)
    $ForwardStack.RemoveAt($ndx)
  }
  else {
    Write-Warning ("{0} is not a location in the location history." -f $Id)
  }
}

# Set the location and update the location history
function Set-LocationEx {
  <#
  .SYNOPSIS
  Set-Location replacement that maintains a location history, allowing easy navigation to previous locations.

  .DESCRIPTION
  Set-Location replacement that maintains a location history, allowing easy navigation to previous locations. The location history contains the list of locations visited in the current PowerShell session. The location history stores up to 100 locations.

  .PARAMETER Path
  Specifies the path of a new working location. "." refers to the current location, ".." refers to the current location's parent, "..." to that location's parent, and so forth. If the location is a leaf element (such as the name of a file), the command will change to the location to the leaf element's container.

  .PARAMETER LiteralPath
  Specifies the path of a new working location. This parameter used exactly as it is typed.

  .PARAMETER Backward
  Changes to the previous location in the location history. You can shorten this parameter name to "-b".

  .PARAMETER Forward
  Changes to the next location in the location history. You can shorten this parameter name to "-f".

  .PARAMETER Id
  Changes to the specified location Id in the location history. You can omit or shorten this parameter name to "-i".

  .PARAMETER CopyToClipboard
  Copies the current or new location to the clipboard. You can shorten this parameter name to "-c".

  .PARAMETER PassThru
  If changing locations, this parameter causes Set-LocationEx to return a PathInfo object that represents the new location.

  .PARAMETER UseTransaction
  If changing locations, this parameter causes Set-LocationEx to include the command in the active transaction. This parameter is valid only when a transaction is in progress. For more information, see help about_Transactions.

  .EXAMPLE
  PS C:\> Set-LocationEx
  Outputs the location history (same as Get-LocationHistory).

  .EXAMPLE
  PS C:\> Set-LocationEx ...
  Changes two levels up from the current location. For example, if you are in C:\Windows\System32\WindowsPowerShell\v1.0, this command will change to C:\Windows\System32.

  .EXAMPLE
  PS C:\> Set-LocationEx 3
  Changes to location Id 3 in the location history. Use Set-LocationEx without parameters or Get-LocationHistory to see the location history. With only a location Id parameter, the -Id parameter name itself is optional.

  .EXAMPLE
  PS C:\> Set-LocationEx "10"
  Changes to the location named "10" in the current location. Without the quotes, Set-LocationEx will interpret the parameter as a location Id. You can also prefix the location with ".\" to prevent Set-LocationEx from interpreting the parameter as a location Id; e.g.: "Set-LocationEx .\10".

  .EXAMPLE
  PS C:\> Set-LocationEx -Backward
  Changes to the previous location in the location history.

  .EXAMPLE
  PS C:\> Set-LocationEx -Forward
  Changes to the next location in the location history.

  .EXAMPLE
  PS C:\> Set-LocationEx -Id 15 -CopyToClipboard
  Changes to location Id 15 and copies its path to the clipboard. The -CopyToClipboard parameter can also be specified as -Clipboard (or -Clip, or just -c).

  .EXAMPLE
  PS C:\> Set-LocationEx $PROFILE
  Changes to the parent location of the file named in the $PROFILE variable.

  .EXAMPLE
  PS C:\> Set-LocationEx -CopyToClipboard
  Copies the current location to the clipboard.
  #>
  [CmdletBinding(DefaultParameterSetName = "Path")]
  param(
    [Parameter(Position = 0,ParameterSetName = "Path",ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String]
    $Path,

    [Parameter(Position = 0,ParameterSetName = "LiteralPath",ValueFromPipelineByPropertyName,Mandatory)]
    [String]
    $LiteralPath,

    [Parameter(Position = 0,ParameterSetName = "Backward",Mandatory)]
    [Switch]
    $Backward,

    [Parameter(Position = 0,ParameterSetName = "Forward",Mandatory)]
    [Switch]
    $Forward,

    [Parameter(Position = 0,ParameterSetName = "Id",Mandatory)]
    [Int]
    $Id,

    [Switch]
    [Alias("Clipboard")]
    $CopyToClipboard,

    [Switch]
    $PassThru,

    [Switch]
    $UseTransaction
  )
  begin {
    # Internal implementation that calls Set-Location
    function SetLocation {
      param(
        $path,

        [Switch]
        $literalPath
      )
      if ( ($PSCmdlet.ParameterSetName -eq "LiteralPath") -or $literalPath ) {
        Set-Location -LiteralPath $path -UseTransaction:$UseTransaction
      }
      else {
        Set-Location $path -UseTransaction:$UseTransaction
      }
      if ( $PassThru ) {
        Write-Output $ExecutionContext.SessionState.Path.CurrentLocation
      }
    }
  }
  process {
    $currentPathInfo = $ExecutionContext.SessionState.Path.CurrentLocation
    if ( $PSCmdlet.ParameterSetName -eq "Backward" ) {
      if ( $BackwardStack.Count -eq 0 ) {
        Write-Warning "No previous location in location history."
      }
      else {
        $lastNdx = $BackwardStack.Count - 1
        $prevPath = $BackwardStack[$lastNdx]
        SetLocation $prevPath -literalPath
        if ( $currentPathInfo.Path -ne $ExecutionContext.SessionState.Path.CurrentLocation.Path ) {
          $ForwardStack.Insert(0,$currentPathInfo.Path)
          $BackwardStack.RemoveAt($lastNdx)
          if ( $CopyToClipboard ) {
            [Windows.Forms.Clipboard]::SetText($ExecutionContext.SessionState.Path.CurrentLocation.Path)
          }
        }
      }
      return
    }
    if ( $PSCmdlet.ParameterSetName -eq "Forward" ) {
      if ( $ForwardStack.Count -eq 0 ) {
        Write-Warning "No next location in location history."
      }
      else {
        $nextPath = $ForwardStack[0]
        SetLocation $nextPath -literalPath
        if ( $currentPathInfo.Path -ne $ExecutionContext.SessionState.Path.CurrentLocation.Path ) {
          $BackwardStack.Add($currentPathInfo.Path)
          $ForwardStack.RemoveAt(0)
          if ( $CopyToClipboard ) {
            [Windows.Forms.Clipboard]::SetText($ExecutionContext.SessionState.Path.CurrentLocation.Path)
          }
        }
      }
      return
    }
    if ( $PSCmdlet.ParameterSetName -eq "Id" ) {
      if ( ($Id -lt 0) -or ($id -gt ($MAX_HISTORY_SIZE - 1)) ) {
        Write-Warning ("Id must be between 0 and {0}." -f ($MAX_HISTORY_SIZE - 1))
        return
      }
      if ( $Id -eq $BackwardStack.Count ) {
        return  # Going nowhere
      }
      if ( $Id -lt $BackwardStack.Count ) {
        $selectedPath = $BackwardStack[$Id]
        SetLocation $selectedPath -literalPath
        if ( $currentPathInfo.Path -ne $ExecutionContext.SessionState.Path.CurrentLocation.Path ) {
          $ForwardStack.Insert(0,$currentPathInfo.Path)
          $BackwardStack.RemoveAt($Id)
          $ndx = $Id
          $count = $BackwardStack.Count - $ndx
          if ( $count -gt 0 ) {
            $itemsToMove = $BackwardStack.GetRange($ndx,$count)
            $ForwardStack.InsertRange(0,$itemsToMove)
            $BackwardStack.RemoveRange($ndx,$count)
          }
          if ( $CopyToClipboard ) {
            [Windows.Forms.Clipboard]::SetText($ExecutionContext.SessionState.Path.CurrentLocation.Path)
          }
        }
      }
      elseif ( ($Id -gt $BackwardStack.Count) -and ($Id -lt ($BackwardStack.Count + 1 + $ForwardStack.Count)) ) {
        $ndx = $Id - ($BackwardStack.Count + 1)
        $selectedPath = $ForwardStack[$ndx]
        SetLocation $selectedPath -literalPath
        if ( $currentPathInfo.Path -ne $ExecutionContext.SessionState.Path.CurrentLocation.Path ) {
          $BackwardStack.Add($currentPathInfo.Path)
          $ForwardStack.RemoveAt($ndx)
          $count = $ndx
          if ( $count -gt 0 ) {
            $itemsToMove = $ForwardStack.GetRange(0,$count)
            $BackwardStack.InsertRange(($BackwardStack.Count),$itemsToMove)
            $ForwardStack.RemoveRange(0,$count)
          }
          if ( $CopyToClipboard ) {
            [Windows.Forms.Clipboard]::SetText($ExecutionContext.SessionState.Path.CurrentLocation.Path)
          }
        }
      }
      else {
        Write-Warning ("{0} is not a location in the location history." -f $Id)
      }
      return
    }
    if ( $PSCmdlet.ParameterSetName -eq "Path" ) {
      $newPath = $Path
    }
    else {
      $newPath = $LiteralPath
    }
    if ( -not $newPath ) {
      if ( -not $CopyToClipboard ) {
        Get-LocationHistory
      }
      else {
        [Windows.Forms.Clipboard]::SetText($ExecutionContext.SessionState.Path.CurrentLocation.Path)
      }
      return
    }
    # Expand ..[.]+ to ..\..[\..]+
    if ( $newPath -like "*...*" ) {
      $regex = [Regex] '\.\.\.'
      while ( $regex.IsMatch($newPath) ) {
        $newPath = $regex.Replace($newPath,'..\..')
      }
    }
    $driveName = ""
    if ( $ExecutionContext.SessionState.Path.IsPSAbsolute($newPath,[Ref] $driveName) -and
         (-not (Test-Path -LiteralPath $newPath -PathType Container)) ) {
      # File or a non-existent path
      $newPath = Split-Path $newPath -Parent
    }
    SetLocation $newPath
    if ( $currentPathInfo.Path -ne $ExecutionContext.SessionState.Path.CurrentLocation.Path ) {
      # Remove oldest entry if size exceeded
      if ( ($BackwardStack.Count + $ForwardStack.Count + 1) -eq $MAX_HISTORY_SIZE ) {
        $BackwardStack.RemoveAt(0)
      }
      $BackwardStack.Add($currentPathInfo.Path)
      # Append new locations to end of stack
      if ( $ForwardStack.Count -gt 0 ) {
        $BackwardStack.InsertRange($BackwardStack.Count,$ForwardStack)
        $ForwardStack.Clear()
      }
      if ( $CopyToClipboard ) {
        [Windows.Forms.Clipboard]::SetText($ExecutionContext.SessionState.Path.CurrentLocation.Path)
      }
    }
  }
}

$PreviousAlias = Get-Alias cd -ErrorAction SilentlyContinue

Set-Alias `
  -Name cd `
  -Value Set-LocationEx `
  -Description "Set-Location replacement that maintains a location history" `
  -Force `
  -Option AllScope `
  -Scope Global

$ExecutionContext.SessionState.Module.OnRemove = {
  if ( $PreviousAlias ) {
    Set-Alias `
    -Name cd `
    -Value $PreviousAlias.Definition `
    -Force `
    -Option $PreviousAlias.Options `
    -Scope Global
  }
}.GetNewClosure()
