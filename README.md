> shell script to install vim the way I like

Has all the plugins I want as git submodules so they can be loaded with
pathogen and their versions are pinned.

To run it:

  1. clone repo
  1. `git submodule init`
  1. run the script
      ```bash
      ./install.sh
      ```

Note: the script will use the package manager to install vim (on Ubuntu or Arch)
so you'll be prompted for `sudo`.

If you get a git submodule that is dirty and wants to be commited, you can
ignore it with the advice from https://stackoverflow.com/a/12332080/1410035.
Edit `.git/config` and add `ignore = dirty`.

# Deoplete
This plugin seems to want the `:UpdateRemotePlugins` command to be run once
after changing the list of packages. At least that's what you get when using the
minimal Deoplete [vimrc
example](https://gist.github.com/zchee/a081e58555bdf4b7335b).
