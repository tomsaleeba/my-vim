#!/bin/bash
# idempotent install script for Tom's vim setup
set -euo pipefail
[ "${DEBUG:-0}" == "1" ] && set -x
thisDir=$(cd `dirname "$0"` && pwd)
bundleDir=$thisDir/dot-vim/bundle

cd $thisDir
# FIXME not sure if this will steamroll changes
git submodule init
git submodule update

isQuickMode=0
if [ ! -z "${1:-}" ]; then
  echo '[INFO] Quick mode enabled'
  isQuickMode=1
fi

function doSymlink {
  linkName=$1
  targetPath=$2
  if [ -L $linkName ]; then
    echo "[INFO] $linkName symlink exists, recreating it"
    rm $linkName
    ln -s $thisDir/$targetPath $linkName
  elif [ -e $linkName ]; then
    echo "[ERROR] $linkName already exists but is not a symlink, refusing to touch it"
    exit 1
  else
    echo "[INFO] $linkName symlink does not exist, creating it"
    ln -s $thisDir/$targetPath $linkName
  fi
}

doSymlink ~/.vimrc vimrc
doSymlink ~/.vim dot-vim

command -v apt-get > /dev/null 2>&1 && {
  # debian/ubuntu
  missing=()
  command -v cmake > /dev/null 2>&1 || missing+=(cmake)
  command -v ctags-exuberant > /dev/null 2>&1 || command -v ctags > /dev/null 2>&1 || missing+=(exuberant-ctags)
  command -v g++ > /dev/null 2>&1 || missing+=(g++)
  command -v nvim > /dev/null 2>&1 || missing+=(neovim)
  command -v pip3 > /dev/null 2>&1 || missing+=(python3-pip)
  command -v ag > /dev/null 2>&1 || missing+=(silversearcher-ag)

  if [ ${#missing[@]} -eq 0 ]; then
    echo '[INFO] neovim and dependencies already installed'
  else
    echo '[INFO] missing packages detected, run:'
    echo
    echo "  sudo apt-get -y install ${missing[*]}"
    echo
  fi

  # msgpack python module (needed by deoplete) is checked separately
  python3 -c "import msgpack" > /dev/null 2>&1 || {
    echo '[INFO] python msgpack module missing, run:'
    echo
    echo '  pip install --user "msgpack>=1"'
    echo
  }
}

command -v pacman > /dev/null 2>&1 && {
  # arch/manjaro
  missing=()
  command -v ctags > /dev/null 2>&1 || missing+=(ctags)
  command -v gcc > /dev/null 2>&1 || missing+=(gcc)
  command -v cmake > /dev/null 2>&1 || missing+=(cmake)
  command -v nvim > /dev/null 2>&1 || missing+=(neovim)
  python3 -c "import pynvim" > /dev/null 2>&1 || missing+=(python-neovim)
  # clang # for vim-codefmt on C

  if [ ${#missing[@]} -eq 0 ]; then
    echo '[INFO] neovim and dependencies already installed'
  else
    echo '[INFO] missing packages detected, run:'
    echo
    echo "  sudo pacman --needed -S ${missing[*]}"
    echo
  fi
}

installPowerline () {
  pushd /tmp > /dev/null
  echo '[INFO] updating powerline fonts (fresh clone every time)'
  fontsDir=fonts
  git clone https://github.com/powerline/fonts.git $fontsDir --depth=1
  cd $fontsDir
  ./install.sh
  cd ..
  rm -fr $fontsDir
  popd > /dev/null
}

nvimConfigPath=$HOME/.config/nvim/init.vim
if [ ! -f "$nvimConfigPath" ]; then
  echo "[INFO] no neovim config ($nvimConfigPath) exists, creating..."
  cat << "HEREDOC" > "$nvimConfigPath"
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
HEREDOC
fi

if [ "$isQuickMode" == "1" ]; then
  echo '[INFO] skipping install/update of powerline fonts'
else
  installPowerline
fi

# Pathogen help tags generation (hoping NORC fixes the fact that it doesn't like :set inccommand)
echo '[INFO] running pathogen#helptags()'
nvim -U NORC -c 'execute pathogen#helptags()' -c q

echo 'The following also need to be installed
  yarn global add prettier     # for vim-codefmt (js)
  yarn global add js-beautify  # for vim-codefmt (html)
  yarn global add neovim       # becuase :checkhealth says we need it
'
