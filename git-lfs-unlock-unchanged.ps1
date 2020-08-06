[CmdletBinding()] # Fail on unknown args
param (
    [switch]$dryrun = $false,
    [switch]$help = $false
)

function Print-Usage {
    Write-Output "Git LFS unlock-unchanged"
    Write-Output "   Unlock all files which are unchanged locally"
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

# git lfs locks --verify is needed to actually check which ones are ours
$locksOutput = git lfs locks --verify
$filesToUnlock = [System.Collections.ArrayList]@()
foreach ($line in $locksOutput) {
    if ($line -match "^O ([^\t]+)\t+(.+)\s+ID:(\d+).*$") {
        $filename = $matches[1]
        $owner = $matches[2]
        $id = $matches[3]
        Write-Verbose "Locked file: $filename"
        if (-not ($modifiedFiles -contains $filename)) {
            $filesToUnlock.Add($filename) > $null
            Write-Verbose "  $filename isn't modified, will unlock"
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
