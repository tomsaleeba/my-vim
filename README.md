> BASH script to install vim the way I like

Has all the plugins I want as git submodules so they can be loaded with
pathogen.

To run it:

  1. clone repo
  1. `git submodule init`
  1. run the script
      ```bash
      ./install.sh
      ```

Note: the script will install vim (on Ubuntu or Arch) so you'll be prompted for
sudo.

If you get a git submodule that is dirty and wants to be commited, you can
ignore it with the advice from https://stackoverflow.com/a/12332080/1410035.
Edit `.git/config` and add `ignore = dirty`.
