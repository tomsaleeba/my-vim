> BASH script to install (g)vim just the way I like

Clones all the plugins I want so they can be loaded with pathogen and builds a .vimrc file.

To run it:

  1. clone repo
  1. run the script
      ```bash
      ./install.sh
      ```

Note: the script will `sudo apt-get` to install gvim, so you'll be prompted for your password.

If you get a git submodule that is dirty and wants to be commited, you can
ignore it with the advice from https://stackoverflow.com/a/12332080/1410035.
Edit `.git/config` and add `ignore = dirty`.
