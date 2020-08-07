# Get all files which have been modified in the working copy or index
function Get-Modified-Files {
    $statusOutput = git status --porcelain --untracked-files=no
    if (!$?) {
        Write-Output "ERROR: failed to call 'git status'"
        Exit 5
    }

    $modifiedFiles = [System.Collections.ArrayList]@()
    foreach ($line in $statusOutput) {
        # Match modified (any non-blank) in working copy or index or both
        if ($line -match "^(?: [^\s]|[^\s] |[^\s][^\s])\s+(.+)$") {
            $filename = $matches[1]
            $modifiedFiles.Add($filename) > $null
        }
    }

    return $modifiedFiles

}
