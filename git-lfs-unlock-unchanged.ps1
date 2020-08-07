[CmdletBinding()] # Fail on unknown args
param (
    [switch]$dryrun = $false,
    [switch]$help = $false
)

function Print-Usage {
    Write-Output "Git LFS unlock-unchanged"
    Write-Output "   Unlock all files which are unchanged locally."
    Write-Output "   To be unlocked a file must not be modified in the working"
    Write-Output "   copy, nor be part of any commits which haven't been pushed."
    Write-Output "Usage:"
    Write-Output "  git-lfs-unlock-unchanged.ps1 [options]"
    Write-Output "Options:"
    Write-Output " "
    Write-Output "  -dryrun      : Don't perform actions, just report what would happen"
    Write-Output "  -verbose     : Print more"
    Write-Output "  -help        : Print this help"

}

$ErrorActionPreference = "Stop"

if ($help) {
    Print-Usage
    Exit 0
}

Write-Output "Checking for locked but unchanged files..."

# Get modified files
$statusOutput = git status --porcelain --untracked-files=no

$modifiedFiles = [System.Collections.ArrayList]@()
foreach ($line in $statusOutput) {
    # Match modified (any non-blank) in working copy or index or both
    if ($line -match "^(?: [^\s]|[^\s] |[^\s][^\s])\s+(.+)$") {
        $filename = $matches[1]
        $modifiedFiles.Add($filename) > $null
    }
}
Write-Verbose ("Modified files:`n    " + ($modifiedFiles -join "`n    "))

$lfsPushOutput = git lfs push --dry-run origin
if (!$?) {
    Write-Output "ERROR: failed to call 'git lfs push --dry-run'"
    Exit 5
}

# Result format is of the form
# push f4ee401c063058a78842bb3ed98088e983c32aa447f346db54fa76f844a7e85e => Path/To/File
# With some potential informationals we can ignore

$filesToBePushed = [System.Collections.ArrayList]@()
foreach ($line in $lfsPushOutput) {
    if ($line -match "^push ([a-f0-9]+)\s+=>\s+(.+)$") {
        $oid = $matches[1]
        $filename = $matches[2]
        $filesToBePushed.Add($filename) > $null
    }
}

# Wrap in @() to avoid collapsing to a single string when only 1 file
$filesToBePushed = @($filesToBePushed | Select-Object -Unique)
Write-Verbose ("Files awaiting push: `n    " + ($filesToBePushed -join "`n    "))

# git lfs locks --verify is needed to actually check which ones are ours
$locksOutput = git lfs locks --verify
if (!$?) {
    Write-Output "ERROR: failed to call 'git lfs locks'"
    Exit 5
}
$filesToUnlock = [System.Collections.ArrayList]@()
foreach ($line in $locksOutput) {
    if ($line -match "^O ([^\t]+)\t+(.+)\s+ID:(\d+).*$") {
        $filename = $matches[1]
        $owner = $matches[2]
        $id = $matches[3]
        Write-Verbose "Locked file: $filename"
        if (-not ($modifiedFiles -contains $filename) -and -not ($filesToBePushed -contains $filename)) {
            $filesToUnlock.Add($filename) > $null
            Write-Verbose "  $filename isn't modified or awaiting push, will unlock"
        }
    }
}

if ($filesToUnlock.Count -gt 0) {
    if ($dryrun) {
        Write-Output ("Would have unlocked:`n    " + ($filesToUnlock -join "`n    "))
    } else {
        git lfs unlock $filesToUnlock
    }
}
