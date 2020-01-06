#!/bin/bash
# idempotent install script for Tom's vim setup
set -euo pipefail

isQuickMode=0
if [ ! -z "${1:-}" ]; then
  echo '[INFO] Quick mode enabled'
  isQuickMode=1
fi

bundleDir=$HOME/.vim/bundle
# TODO add $HOME/.config/nvim/init.vim for neovim

cd $HOME
echo '[INFO] creating required dirs'
mkdir -p \
  $bundleDir \
  $HOME/.vim/autoload \
  $HOME/.vim/temp_dirs
curl -LSso $HOME/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

clone_or_pull () {
  # lets us make this script idempotent
  repoUrl=$1
  dirName=`basename $repoUrl`
  if [ ! -d $dirName ]; then
    git clone --depth 1 $repoUrl $dirName
  else
    pushd $dirName > /dev/null
    git pull
    popd > /dev/null
  fi
}

cd $bundleDir

# Install gvim/neovim. Even if you want to use vim in a terminal, this is good
# because you get the fully featured vim (with clipboard integration)
if [ "$isQuickMode" == "1" ]; then
  echo '[INFO] skipping gvim/neovim install or update'
else
  echo '[INFO] installing/updating gvim'
  command -v apt-get > /dev/null 2>&1 && {
    # debian/ubuntu
    sudo apt-get -y install \
      exuberant-ctags \
      vim-gtk \
      libpython2.7-dev \
      g++ \
      cmake
  }
  command -v pacman > /dev/null 2>&1 && {
    # arch/manjaro
    sudo pacman --noconfirm --needed -Sy \
      ctags \
      gcc \
      cmake \
      neovim \
      python-neovim \
      # clang # for vim-codefmt on C
  }
fi

# YouCompleteMe
ycmRepo=https://github.com/Valloric/YouCompleteMe
if [ "$isQuickMode" == "1" ]; then
  # if we pull fresh stuff but don't build it, things break. So just don't touch anything
  echo '[INFO] skipping YCM build'
else
  echo '[INFO] processing YouCompleteMe'
  clone_or_pull $ycmRepo
  pushd YouCompleteMe > /dev/null
   git submodule sync --recursive
  git submodule update --init --recursive
  # TODO only run following if changes are present
  # maybe by comparing `find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "` before and after
  python install.py --java-completer
  # TODO make sure typescript is installed for JS support: npm install -g typescript
  popd > /dev/null
fi

# Install and compile procvim.vim
echo '[INFO] processing vimproc'
vimprocRepo=https://github.com/Shougo/vimproc.vim
clone_or_pull $vimprocRepo
pushd vimproc.vim > /dev/null
make
popd > /dev/null

# install plugins
declare -a plugins=(
  "https://github.com/Raimondi/delimitMate"
  "https://github.com/SirVer/ultisnips" # snippet engine
    "https://github.com/honza/vim-snippets" # the snippets themselves
  "https://github.com/airblade/vim-gitgutter"
  "https://github.com/bling/vim-airline"
  "https://github.com/chaoren/vim-wordmotion" # camelcase support
  "https://github.com/easymotion/vim-easymotion"
  "https://github.com/ekalinin/Dockerfile.vim"
  "https://github.com/elzr/vim-json"
  "https://github.com/gabesoft/vim-ags" # silver searcher integrations, :Ags
    "https://github.com/dbakker/vim-projectroot" # run :Ags in project root
  "https://github.com/google/vim-codefmt" # run code formatters like yapf
    "https://github.com/google/vim-glaive"
    "https://github.com/google/vim-maktaba"
  "https://github.com/kien/ctrlp.vim"
  "https://github.com/leafgarland/typescript-vim" # syntax file and other settings for TS, no autocomplete
  "https://github.com/machakann/vim-highlightedyank"
  "https://github.com/majutsushi/tagbar" # :TagbarToggle to show file overview
  "https://github.com/maxbrunsfeld/vim-yankstack" # <M-p> to paste/cycle back, <M-P> to cycle forward
  "https://github.com/michaeljsmith/vim-indent-object" # select text objects by indent
  "https://github.com/nathanaelkane/vim-indent-guides" # visual indent level, <leader>ig to toggle
  "https://github.com/pangloss/vim-javascript"
  "https://github.com/plasticboy/vim-markdown"
  "https://github.com/posva/vim-vue"
  "https://github.com/qpkorr/vim-bufkill" # :BD to kill buffer without saving
  "https://github.com/tyru/caw.vim" # commenter that works with vue, where NERDcommenter doesn't
    "https://github.com/Shougo/context_filetype.vim" # support for mutli-context files: vue, html
  "https://github.com/scrooloose/nerdtree"
    "https://github.com/jistr/vim-nerdtree-tabs" # common state for NerdTree on all tabs
  "https://github.com/scrooloose/syntastic"
  "https://github.com/stephpy/vim-yaml"
  "https://github.com/terryma/vim-expand-region" # use + to expand or _ to reduce selection
  "https://github.com/tomtom/tlib_vim"
  "https://github.com/tpope/vim-repeat"
  "https://github.com/tpope/vim-surround"
  "https://github.com/tpope/vim-unimpaired" # [ and ] prefixed commands
  "https://github.com/yssl/QFEnter"
  "https://github.com/alvan/vim-closetag"
  # theme:
  # Matching terminal theme available at: https://github.com/morhetz/gruvbox-contrib
  "https://github.com/morhetz/gruvbox"
)

echo '[INFO] checking for orphaned plugins (to delete)'
for currDirPath in $bundleDir/*; do
  currDir=`basename "$currDirPath"`
  found=false
  for currRepo in "${plugins[@]} $ycmRepo $vimprocRepo"; do
    echo $currRepo | grep --fixed-strings --silent $currDir && {
      found=true
      break
    }
  done
  eval $found || {
    echo "Deleting $currDir"
    rm -fr $bundleDir/$currDir
  }
done

for curr in "${plugins[@]}"; do
  echo "[INFO] processing $curr"
  clone_or_pull "$curr" &
done
wait # for parallel clone_or_pulls to finish

installPowerline () {
  pushd /tmp > /dev/null
  echo '[INFO] updating powerline fonts (fresh clone every time)'
  git clone https://github.com/powerline/fonts.git --depth=1
  cd fonts
  ./install.sh
  cd ..
  rm -fr fonts
  popd > /dev/null
}
if [ "$isQuickMode" == "1" ]; then
  echo '[INFO] skipping install/update of powerline fonts'
else
  installPowerline
fi

# Pathogen help tags generation (hoping NORC fixes the fact that it doesn't like :set inccommand)
echo '[INFO] running pathogen#helptags()'
vim -U NORC -c 'execute pathogen#helptags()' -c q

echo 'The following also need to be installed
  yarn global add prettier     # for vim-codefmt (js)
  yarn global add js-beautify  # for vim-codefmt (html)
'
