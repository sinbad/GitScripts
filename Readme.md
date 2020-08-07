# Steve's Git (LFS+Locking) Helper Scripts

This is a collection of Powershell scripts I use to help me manage a few tricky
Git repo tasks, mostly those related to using [Git LFS](https://git-lfs.github.com/)
and its [file locking feature](https://github.com/git-lfs/git-lfs/wiki/File-Locking). 

All these scripts work with the regular Powershell 5.1 shipped with Windows 10, 
but should also work fine with later versions.

Wrapper .bat files are provided in case you want to call these from somewhere
other than a Powershell prompt.

## Push And Unlock Files

Push a branch to a remote, and unlock any files which you pushed (that aren't modified)

```
Usage:
  git-lfs-push-and-unlock.ps1 [options] <remote> [<ref>...]
 
Arguments:
  <remote>     :  The remote to push to (required)
  <ref>...     :  One or more refs to push (optional, current branch assumed

Options:
  -dryrun      : Don't perform actions, just report what would happen
  -verbose     : Print more
  -help        : Print this help
```

I added a feature to the [UE4 Git LFS Plugin](https://github.com/SRombauts/UE4GitPlugin) 
which automatically unlocked files on push, this script is a version of that you 
can run from anywhere. I find it useful when running a mixture of in-UE and
out-of-UE workflow. 

It figures out which lockable LFS files you're pushing, and unlocks them
if the push was successful, so long as you don't have further uncommitted
modifications.

## Unlock unchanged files

If you suspect that you have some file locks you don't need, run this command
and it will unlock anything you have locked, which you don't have outstanding
changes for. 

```
Usage:
  git-lfs-unlock-unchanged.ps1 [options]

Options:
 
  -dryrun      : Don't perform actions, just report what would happen
  -verbose     : Print more
  -help        : Print this help
```

"Unchanged" means that there are no uncommitted changes, *and* no commits on
this branch that contain those files that haven't been pushed to your default
remote yet.

## Fix file attributes

Git LFS makes lockable files read-only on checkout or unlock to prevent
accidental changes. Sometimes the attributes can get out of sync though, 
so this script checks them all and fixes where necessary.

```
Usage:
  git-lfs-fix-attributes.ps1 [options]

Options:
 
  -dryrun      : Don't perform actions, just report what would happen
  -verbose     : Print more
  -help        : Print this help
```