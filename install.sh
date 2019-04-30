#!/bin/bash
# idempotent install script for Tom's vim setup
set -euo pipefail

isSkipYCMBuild=0
if [ ! -z "${1:-}" ]; then
  echo '[INFO] YCM build will be skipped'
  isSkipYCMBuild=1
fi

bundleDir=$HOME/.vim/bundle
vimrc=$HOME/.vimrc

cd $HOME
echo '[INFO] creating required dirs'
mkdir -p \
  $bundleDir \
  $HOME/.vim/autoload \
  $HOME/.vim/temp_dirs
curl -LSso $HOME/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
uniqueId=`date +%Y%m%d_%H%M`
old=$HOME/.oldvimrc_$uniqueId
mv -f $vimrc $old > /dev/null && echo "backed up .vimrc to $old" # FIXME might need to pipe stderr to /dev/null
touch $vimrc

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

# Install gvim
# TODO add flag to skip this
echo '[INFO] installing/updating gvim'
command -v apt-get > /dev/null 2>&1 && {
  sudo apt-get -y install \
    exuberant-ctags \
    vim-gtk \
    libpython2.7-dev \
    g++ \
    cmake
}
command -v pacman > /dev/null 2>&1 && {
  sudo pacman --noconfirm --needed -Sy \
    ctags \
    gvim \
    gcc \
    cmake
}

# YouCompleteMe
if [ "$isSkipYCMBuild" == "1" ]; then
  # if we pull fresh stuff but don't build it, things break. So just don't touch anything
  echo '[INFO] skipping YCM build'
else
  echo '[INFO] processing YouCompleteMe'
  clone_or_pull https://github.com/Valloric/YouCompleteMe
  pushd YouCompleteMe
  git submodule update --init --recursive
  # TODO only run following if changes are present
  # maybe by comparing `find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" "` before and after
  python install.py
  popd
fi

# Install and compile procvim.vim
echo '[INFO] processing vimproc'
clone_or_pull https://github.com/Shougo/vimproc.vim
pushd vimproc.vim
make
popd

# install plugins
declare -a plugins=(
  "https://github.com/Raimondi/delimitMate"
  "https://github.com/SirVer/ultisnips"
  "https://github.com/airblade/vim-gitgutter"
  "https://github.com/bling/vim-airline"
  "https://github.com/chaoren/vim-wordmotion.git"
  "https://github.com/easymotion/vim-easymotion"
  "https://github.com/ekalinin/Dockerfile.vim"
  "https://github.com/elzr/vim-json"
  "https://github.com/godlygeek/tabular"
  "https://github.com/groenewege/vim-less"
  "https://github.com/honza/vim-snippets"
  "https://github.com/jistr/vim-nerdtree-tabs"
  "https://github.com/jlanzarotta/bufexplorer"
  "https://github.com/kien/ctrlp.vim"
  "https://github.com/leafgarland/typescript-vim"
  "https://github.com/majutsushi/tagbar"
  "https://github.com/marcweber/vim-addon-mw-utils"
  "https://github.com/mbbill/undotree"
  "https://github.com/michaeljsmith/vim-indent-object"
  "https://github.com/nathanaelkane/vim-indent-guides"
  "https://github.com/othree/html5.vim"
  "https://github.com/pangloss/vim-javascript"
  "https://github.com/plasticboy/vim-markdown"
  "https://github.com/posva/vim-vue"
  "https://github.com/qpkorr/vim-bufkill"
  "https://github.com/Quramy/tsuquyomi"
  "https://github.com/scrooloose/nerdcommenter"
  "https://github.com/scrooloose/nerdtree"
  "https://github.com/scrooloose/syntastic"
  "https://github.com/stephpy/vim-yaml"
  "https://github.com/terryma/vim-expand-region"
  "https://github.com/terryma/vim-multiple-cursors"
  "https://github.com/tomtom/tlib_vim"
  "https://github.com/tpope/vim-fugitive"
  "https://github.com/tpope/vim-haml"
  "https://github.com/tpope/vim-repeat"
  "https://github.com/tpope/vim-surround"
  "https://github.com/tpope/vim-unimpaired"
  "https://github.com/vim-scripts/EasyGrep"
  "https://github.com/vim-scripts/YankRing.vim"
  "https://github.com/vim-scripts/mru.vim"
  "https://github.com/vim-scripts/taglist.vim"
  "https://github.com/yssl/QFEnter"
  # theme:
  # Matching terminal theme available at: https://github.com/morhetz/gruvbox-contrib
  "https://github.com/morhetz/gruvbox.git"
)
for curr in "${plugins[@]}"; do
  echo "[INFO] processing $curr"
  clone_or_pull "$curr" &
done
installPowerline () {
  pushd /tmp
  git clone https://github.com/powerline/fonts.git --depth=1
  cd fonts
  ./install.sh
  cd ..
  rm -fr fonts
  popd
}
installPowerline &
wait # for parallel clone_or_pulls to finish

# add some awesomeness to the .vimrc
echo '[INFO] updating the vimrc'

# must be before first ColorScheme command so it doesn't get reset (http://vim.wikia.com/wiki/Highlight_unwanted_spaces)
echo 'autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red'     > $vimrc

curl -s https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim    >> $vimrc
echo '" end of amix/basic.vim'                                                  >> $vimrc
curl -s https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/extended.vim >> $vimrc
echo '" end of amix/extended.vim'                                               >> $vimrc
sed -i '/colorscheme peaksea/d' $vimrc
sed -i '/Parenthesis.bracket/,+18 d' $vimrc # remove the $ shortcuts from amix

# add our own config to .vimrc
cat >> $vimrc <<EOF
execute pathogen#infect()
syntax on
filetype plugin indent on
" thanks https://stackoverflow.com/a/6726904/1410035 for split settings
set splitbelow
set splitright
set tw=120

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Huge thanks to "Amir Salihefendic" : https://github.com/amix
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" => YouCompleteMe plugin
""""""""""""""""""""""""""""""
" use <C-y> to stop completion (dismiss popup)
let g:ycm_autoclose_preview_window_after_insertion = 1
map <F9> :YcmCompleter FixIt<CR>

""""""""""""""""""""""""""""""
" => bufExplorer plugin
""""""""""""""""""""""""""""""
let g:bufExplorerDefaultHelp=0
let g:bufExplorerShowRelativePath=1
let g:bufExplorerFindActive=1
let g:bufExplorerSortBy='name'
map <leader>o :BufExplorer<cr>


""""""""""""""""""""""""""""""
" => MRU plugin
""""""""""""""""""""""""""""""
let MRU_Max_Entries = 400
map <leader>f :MRU<CR>


""""""""""""""""""""""""""""""
" => YankRing
""""""""""""""""""""""""""""""
let g:yankring_history_dir = '$HOME/.vim/temp_dirs'


""""""""""""""""""""""""""""""
" => CTRL-P
""""""""""""""""""""""""""""""
" use ctrl+y to cancel popup
let g:ctrlp_working_path_mode = 'ra'

let g:ctrlp_map = '<c-f>'
map <c-b> :CtrlPBuffer<cr>

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist|lcov-report)|(\.(swp|ico|git|svn|venv|DS_Store|pytest_cache|nuxt))$'
let g:ctrlp_show_hidden = 1


""""""""""""""""""""""""""""""
" => Vim grep
""""""""""""""""""""""""""""""
let Grep_Skip_Dirs = 'RCS CVS SCCS .svn generated'
set grepprg=/bin/grep\ -nH


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-markdown
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vim_markdown_folding_disabled = 1


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Nerd Tree
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:NERDTreeWinPos = "left"
let g:NERDTreeWinSize=40
map <leader>nn :NERDTreeToggle<cr>
map <leader>nb :NERDTreeFromBookmark
map <leader>nf :NERDTreeFind<cr>
let NERDTreeShowHidden=1


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Nerd Tree Tabs
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => TagBar
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <F8> :TagbarToggle<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-multiple-cursors
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:multi_cursor_next_key="\<C-s>"


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => surround.vim config
" Annotate strings with gettext http://amix.dk/blog/post/19678
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
vmap Si S(i_<esc>f)
au FileType mako vmap Si S"i\${ _(<esc>2f"a) }<esc>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Vim-Airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Always show statusline
set laststatus=2


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => buffer switch
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <Leader>. :bn<CR>
nnoremap <Leader>, :bp<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => color and theme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set background=dark
colorscheme gruvbox
set relativenumber
set number
set cursorline


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Snippets
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
let g:UltiSnipsEditSplit="vertical"


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => undotree
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <F5> :UndotreeToggle<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Set Vim working directory to the current location
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set autochdir


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Set Tabular
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader=','
if exists(":Tabularize")
  nmap <Leader>a= :Tabularize /=<CR>
  vmap <Leader>a= :Tabularize /=<CR>
  nmap <Leader>a: :Tabularize /:\zs<CR>
  vmap <Leader>a: :Tabularize /:\zs<CR>
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => QFEnter
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set switchbuf=useopen " make sure new tabs don't open with <CR>
let g:qfenter_keymap = {}
let g:qfenter_keymap.vopen = ['<C-v>']
let g:qfenter_keymap.hopen = ['<C-CR>', '<C-s>', '<C-x>']
let g:qfenter_keymap.topen = ['<C-t>']


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Indent Guides
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_guide_size = 1
nmap <F6> :IndentGuidesToggle<CR>
set ts=2 sw=2 et


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-vue
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vue_disable_pre_processors=1 " make the plugin responsive


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => UTF-8
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set encoding=utf-8


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tsuquyomi
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:tsuquyomi_disable_default_mappings = 1


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => tagbar TypeScript
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:tagbar_type_typescript = {
  \ 'ctagstype': 'typescript',
  \ 'kinds': [
    \ 'c:classes',
    \ 'n:modules',
    \ 'f:functions',
    \ 'v:variables',
    \ 'v:varlambdas',
    \ 'm:members',
    \ 'i:interfaces',
    \ 'e:enums',
  \ ]
\ }

" We need to do this to stop ft-sql from continually complaining with the error:
" SQLComplete: the dbext plugin must be loaded for dynamic sql completion
let g:omni_sql_no_default_maps = 1

if has('gui_running')
  set guifont=Hack\ 12 " comes from https://github.com/powerline/fonts/tree/master/Hack
endif

" uses ColorScheme defined at start of .vimrc
match ExtraWhitespace /\s\+$/
EOF

# Pathogen help tags generation
echo '[INFO] running pathogen#helptags()'
vim -c 'execute pathogen#helptags()' -c q

