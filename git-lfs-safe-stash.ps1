[CmdletBinding()] # Fail on unknown args
param (
    [switch]$dryrun = $false,
    [switch]$help = $false,
    [Parameter(ValueFromRemainingArguments)]
    $otherStashArgs
)

function Print-Usage {
    Write-Output "Git LFS safe stash"
    Write-Output "   git-stash is unsafe with Git LFS files, since LFS files that"
    Write-Output "   have never been staged will not have their actual contents"
    Write-Output "   in the LFS store, and the stash will only store a pointer file."
    Write-Output "   This means when you unstash you will lose your real file content."
    Write-Output " "
    Write-Output "   To fix this, we detect unstaged modifications to LFS files"
    Write-Output "   and stage / unstage them once to write the contents into"
    Write-Output "   the local LFS store, so they can be retrieved later."
    Write-Output " "
    Write-Output "   CAUTION: Do NOT run 'git lfs prune' when you have stashes"
    Write-Output "   containing LFS content; git-lfs considers them unreferenced"
    Write-Output "   and will delete them, rendering the stash useless."
    Write-Output "Usage:"
    Write-Output "  git-lfs-stash.ps1 [options] [normal-stash-args]"
    Write-Output " "
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

# First get the list of LFS files in the repo (yes, all of them)
# This is faster than getting the diff of individual files to check for them being LFS
# or trying to replicate the matching rules of LFS (fragile)
$lfsFilesOut = git lfs ls-files -n

# We're interested in any modified files which haven't been staged. Their
# content isn't in the LFS object dir, and so when git stash removes their
# contents and only puts the pointer file in the diff, the contents will be lost
# Staged changes are "M ", unstaged are " M"
# We don't care about added / staged files, they're already in the LFS dir

# Get the list of unstaged files
# It would be nice if "git lfs status" only reported LFS files, but it doesn't
# it also includes non-lfs files, so we still have work to do
$statusOutput = git status --porcelain --untracked-files=no

$unstagedFiles = [System.Collections.ArrayList]@()
foreach ($line in $statusOutput) {
    if ($line -match "^ M\s+(.+)$") {
        $filename = $matches[1]
        $unstagedFiles.Add($filename) > $null
    }
}

if ($unstagedFiles.Count -gt 0) {
    Write-Verbose ("All Unstaged Files:`n    " + ($unstagedFiles -join "`n    "))

    # Now match unstaged files to LFS files, those are the ones we care about
    $unstagedLfs = @($unstagedFiles | Where-Object {$lfsFilesOut -contains $_})

    if ($unstagedLfs.Count -gt 0) {
        Write-Output ("Fixing LFS changes that would be lost by stashing:`n    " + ($unstagedLfs -join "`n"))

        # We don't need to use "git add" (which could have side effects if you
        # have the same file in the index AND modified locally)
        # We just need to pass the file content through the LFS clean filter
        # This calculates the OID and writes the content to the LFS folder

        foreach ($filename in $unstagedLfs) {
            # Powershell is terrible at dealing with binary data, piping always
            # messes with it. So drop to CMD for this
            if (-not $dryrun) {
                cmd /C "git lfs clean < $filename" > $null
            }
        }
    }
}

git stash $otherStashArgs



