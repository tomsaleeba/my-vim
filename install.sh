#!/bin/bash
# idempotent install script for Tom's vim setup
set -euo pipefail

isQuickMode=0
if [ ! -z "${1:-}" ]; then
  echo '[INFO] Quick mode enabled'
  isQuickMode=1
fi

bundleDir=$HOME/.vim/bundle
vimrc=$HOME/.vimrc
# TODO add $HOME/.config/nvim/init.vim for neovim

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
find . \
  -maxdepth 1 \
  -name '.oldvimrc_*' \
  | tail -n +6 | xargs rm # only keep 6 backups
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
      gvim \
      gcc \
      cmake
      # neovim python-neovim \
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
  "https://github.com/SirVer/ultisnips" # snippet engine
    "https://github.com/honza/vim-snippets" # the snippets themselves
  "https://github.com/airblade/vim-gitgutter"
  "https://github.com/bling/vim-airline"
  "https://github.com/chaoren/vim-wordmotion"
  "https://github.com/easymotion/vim-easymotion"
  "https://github.com/ekalinin/Dockerfile.vim"
  "https://github.com/elzr/vim-json"
  "https://github.com/gabesoft/vim-ags" # silver searcher integrations, :Ags
    "https://github.com/dbakker/vim-projectroot" # run :Ags in project root
  "https://github.com/godlygeek/tabular" # <leader>a (mapped below) to autoformat markdown tables and JS dicts
  "https://github.com/google/vim-codefmt" # run code formatters like yapf
    "https://github.com/google/vim-glaive"
    "https://github.com/google/vim-maktaba"
  "https://github.com/groenewege/vim-less"
  "https://github.com/kien/ctrlp.vim"
  "https://github.com/leafgarland/typescript-vim" # syntax file and other settings for TS, no autocomplete
  "https://github.com/machakann/vim-highlightedyank"
  "https://github.com/majutsushi/tagbar" # :TagbarToggle to show file overview
  "https://github.com/maxbrunsfeld/vim-yankstack" # <M-p> to paste/cycle back, <M-P> to cycle forward
  "https://github.com/mbbill/undotree"
  "https://github.com/michaeljsmith/vim-indent-object" # select text objects by indent
  "https://github.com/nathanaelkane/vim-indent-guides" # visual indent level, <leader>ig to toggle
  "https://github.com/othree/html5.vim"
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
  "https://github.com/tpope/vim-fugitive"
  "https://github.com/tpope/vim-haml"
  "https://github.com/tpope/vim-repeat"
  "https://github.com/tpope/vim-surround"
  "https://github.com/tpope/vim-unimpaired"
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

# Pathogen help tags generation (run this before writing vimrc as it doesn't like :set inccommand)
echo '[INFO] running pathogen#helptags()'
vim -c 'execute pathogen#helptags()' -c q

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
set tw=79
set encoding=utf-8

" thanks https://stackoverflow.com/a/6726904/1410035 for split settings
set splitbelow
set splitright

" color and theme
set background=dark
colorscheme gruvbox
set relativenumber
set number
set cursorline

" Set Vim working directory to the current location
set autochdir

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Huge thanks to "Amir Salihefendic" : https://github.com/amix
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""
" => YouCompleteMe plugin
""""""""""""""""""""""""""""""
" use <C-y> to stop completion (dismiss popup)
let g:ycm_autoclose_preview_window_after_insertion = 1
map <leader>f :YcmCompleter FixIt<CR>


""""""""""""""""""""""""""""""
" => CTRL-P
""""""""""""""""""""""""""""""
" use ctrl+y to cancel popup
let g:ctrlp_working_path_mode = 'ra'

let g:ctrlp_map = '<C-f>'
map <C-b> :CtrlPBuffer<CR>

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist|lcov-report)|(\.(swp|ico|git|svn|venv|DS_Store|pytest_cache|nuxt))$'
let g:ctrlp_show_hidden = 1


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
" => TagBar
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <leader>o :TagbarToggle<CR>
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


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => surround.vim config
" Annotate strings with gettext http://amix.dk/blog/post/19678
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
vmap Si S(i_<esc>f)
au FileType mako vmap Si S"i\${ _(<esc>2f"a) }<esc>
xmap S <Plug>VSurround " prefer this over the conflicting yankstack mapping


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Vim-Airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Always show statusline
set laststatus=2


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
nnoremap <leader>u :UndotreeToggle<cr>


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
set ts=2 sw=2 et


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => michaeljsmith/vim-indent-object
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"| Key bindings | Description                                                 |
"| ------------ | ----------------------------------------------------------- |
"| <count>ai    | **A**n **I**ndentation level and line above.                |
"| <count>ii    | **I**nner **I**ndentation level (**no line above**).        |
"| <count>aI    | **A**n **I**ndentation level and lines above/below.         |
"| <count>iI    | **I**nner **I**ndentation level (**no lines above/below**). |


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-vue
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vue_disable_pre_processors=1 " make the plugin responsive
autocmd FileType vue syntax sync fromstart " run highlight from start


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => caw
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" need to repeat the default map otherwise it won't get mapped
nmap gcc <Plug>(caw:hatpos:toggle)
xmap gcc <Plug>(caw:hatpos:toggle)
nmap <leader><space> <Plug>(caw:hatpos:toggle)
xmap <leader><space> <Plug>(caw:hatpos:toggle)


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => context_filetype.vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" needs to be run for context sensitive commenting to work, not sure why
autocmd VimEnter * silent echo context_filetype#get()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-ags
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>g :ProjectRootExe Ags<space>
let g:ags_agcontext = 0


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => syntastic
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:syntastic_java_checkers = [] " disable so YCM can handle
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => google/vim-codefmt
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ensure you 'pip install --user yapf'
" copied from https://github.com/google/vim-codefmt
augroup autoformat_settings
  autocmd FileType bzl AutoFormatBuffer buildifier
  autocmd FileType c,cpp,proto AutoFormatBuffer clang-format
  autocmd FileType javascript AutoFormatBuffer prettier
  autocmd FileType dart AutoFormatBuffer dartfmt
  autocmd FileType go AutoFormatBuffer gofmt
  autocmd FileType gn AutoFormatBuffer gn
  autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
  autocmd FileType java AutoFormatBuffer google-java-format
  autocmd FileType python AutoFormatBuffer yapf
  " Alternative: autocmd FileType python AutoFormatBuffer autopep8
augroup END
" the glaive#Install() should go after the "call vundle#end()"
call glaive#Install()
" Enable codefmt's default mappings on the <Leader>= prefix.
Glaive codefmt plugin[mappings]
Glaive codefmt prettier_options=\`['--single-quote', '--trailing-comma=all', '--arrow-parens=always', '--print-width=80', '--no-bracket-spacing', '--no-semi']\`


" We need to do this to stop ft-sql from continually complaining with the error:
" SQLComplete: the dbext plugin must be loaded for dynamic sql completion
let g:omni_sql_no_default_maps = 1

if has('gui_running')
  set guifont=Hack\ 12 " comes from https://github.com/powerline/fonts/tree/master/Hack
endif

" uses ColorScheme defined at start of .vimrc
match ExtraWhitespace /\s\+$/

if has('nvim')
  " map Esc to exit terminal mode (:te)
  tnoremap <Esc> <C-\><C-n>

  " live substitute preview and highlighting
  set inccommand=nosplit
else
  " allow alt+<letter> keys to work in a terminal, for things like alt+j/k to move lines
  " thanks https://stackoverflow.com/a/10216459
  let c='a'
  while c <= 'z'
    exec "set <A-".c.">=\e".c
    exec "imap \e".c." <A-".c.">"
    let c = nr2char(1+char2nr(c))
  endw
  set timeout ttimeoutlen=50
endif
EOF

echo 'The following also need to be installed
  yarn global add prettier     # for vim-codefmt (js)
  yarn global add js-beautify  # for vim-codefmt (html)
'
