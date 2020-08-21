[CmdletBinding()] # Fail on unknown args
param (
    [switch]$dryrun = $false,
    [switch]$help = $false
)

function Print-Usage {
    Write-Output "Git LFS Fix Attributes"
    Write-Output "   Fix the read-only attributes on LFS files which are lockable"
    Write-Output "   but which are not currently locked. Unlocked files are"
    Write-Output "   made read-only on checkout but it's possible to accidentally"
    Write-Output "   have files left read/write when they aren't locked, which"
    Write-Output "   will only get fixed the next time this file is checked out."
    Write-Output "Usage:"
    Write-Output "  git-lfs-fix-attributes.ps1 [options]"
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

. $PSScriptRoot\inc\locking.ps1

Write-Output "Checking file attributes..."
$lockableLfsFiles = Get-All-Lockable-Files
Write-Verbose ("Checking attributes on lockable files:`n    " + ($lockableLfsFiles -join "`n    "))

# Now get active locks
$lockedFiles = Get-Locked-Files
Write-Verbose ("Currently locked files:`n    " + ($lockedFiles -join "`n    "))

$numFixed = 0
foreach ($filename in $lockableLfsFiles) {
    $shouldBeReadOnly = -not ($lockedFiles -contains $filename)
    $isReadOnly = Get-ItemProperty -Path $filename | Select-Object -Expand IsReadOnly
    if ($isReadOnly -ne $shouldBeReadOnly) {
        if ($dryrun) {
            Write-Verbose "${filename}: read-only should be $shouldBeReadOnly"
        } else {
            Write-Output "${filename}: setting read-only=$shouldBeReadOnly"
            Set-ItemProperty -Path $filename -Name IsReadOnly -Value $shouldBeReadOnly
        }
        ++$numFixed
    }
}

if ($numFixed -gt 0) {
    if ($dryrun) {
        Write-Output "Would have fixed $numFixed file attributes."
    } else {
        Write-Output "Fixed $numFixed file attributes."
    }
} else {
    Write-Output "All file attributes are OK"
}
