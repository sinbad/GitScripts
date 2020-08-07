# Get an array of all the lockable files in the repository
function Get-All-Lockable-Files {

    # First get the list of LFS files in the repo (yes, all of them)
    $allLfsFiles = git lfs ls-files -n
    if (!$?) {
        Write-Output "ERROR: failed to call 'git lfs ls-files'"
        Exit 5
    }

    # Filter these files to those which are lockable
    $lockableLfsFiles = [System.Collections.ArrayList]@()
    # send files from stdin so we don't have to worry about command line length
    $lockableAttrOut = ($allLfsFiles -join "`n") | git check-attr lockable --stdin
    foreach ($line in $lockableAttrOut) {
        if ($line -match "^([^:]+):\slockable:\sset$") {
            $filename = $matches[1]
            $lockableLfsFiles.Add($filename) > $null
        }
    }

    return $lockableLfsFiles
}

# Get an array of the files currently locked by the current user
function Get-Locked-Files {
    $lfsLocksOutput = git lfs locks --verify
    if (!$?) {
        Write-Output "ERROR: failed to call 'git lfs locks'"
        Exit 5
    }
    $lockedFiles = [System.Collections.ArrayList]@()
    # Output is of the form (for owned)
    # O Path/To/File\tsteve\tID:268
    foreach ($line in $lfsLocksOutput) {
        if ($line -match "^O ([^\t]+)\t+(.+)\s+ID:(\d+).*$") {
            $filename = $matches[1]
            $owner = $matches[2]
            $id = $matches[3]
            $lockedFiles.Add($filename) > $null
        }
    }
    
    return $lockedFiles
    
}