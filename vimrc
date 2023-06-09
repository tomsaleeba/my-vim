autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red

" Ripped off parts from https://github.com/amix/vimrc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sets how many lines of history VIM has to remember
set history=500

" not a fan on the page scrolling with shift-arrow
nmap <S-Down> <NOP>
nmap <S-UP> <NOP>
vmap <S-Down> <NOP>
vmap <S-UP> <NOP>
imap <S-Down> <NOP>
imap <S-UP> <NOP>

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = "\<space>"

" Fast saving
nmap <leader>w :w!<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
command! W w !sudo tee % > /dev/null


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set scrolloff=3
set mouse=

" Turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

"Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Properly disable sound on errors on MacVim
if has("gui_macvim")
    autocmd GUIEnter * set vb t_vb=
endif


set foldcolumn=0

" for interview docs
autocmd FileType markdown highlight AskGroup ctermbg=red ctermfg=yellow
autocmd FileType markdown match AskGroup /ASK/

" to fix busted syntax highlighting, thanks https://stackoverflow.com/a/17189261/1410035
noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git etc anyway...
set nobackup
set nowb
set noswapfile


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == N spaces
" FIXME create something smarter than *let's configure setting per repo*
" https://stackoverflow.com/questions/1889602
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr

set ai "Auto indent
" FIXME smartindent responsible for
" - removing indent on }
" - the annoying '# gets zero indent *always*' behaviour
"   - the inoremap fixes the insert behaviour, but
"   - does *not* fix the 'cannot indent # lines' bug
set si "Smart indent
inoremap # X#
set wrap "Wrap lines

" thanks https://stackoverflow.com/a/49944815/1410035
nnoremap <silent> * :let @/= '\<\$\?' . substitute(expand('<cword>'), '^\$', '', '') . '\>' <bar> set hls <cr>
" FIXME support #, might need to set v:searchforward=0 but not sure how

vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>

" base64 encoding and decoding visual selection
"   thanks https://www.jvt.me/posts/2022/03/03/vim-command-visual-selection/
vnoremap <silent> <leader>be c<C-R>=system('base64 -w0', @")<CR><ESC>
vnoremap <silent> <leader>bd c<C-R>=system('base64 -d', @")<CR><ESC>

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Smart way to move between windows
nmap <C-j> <C-W>j
nmap <C-k> <C-W>k
nmap <C-h> <C-W>h
nmap <C-l> <C-W>l
nmap <leader>j <c-w><c-p>

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <leader>cd :cd %:p:h<cr>:pwd<cr>

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Editing mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <M-j> mz:m+<cr>`z
nmap <M-k> mz:m-2<cr>`z
vmap <M-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <M-k> :m'<-2<cr>`>my`<mzgv`yo`z

if has("mac") || has("macunix")
  nmap <D-j> <M-j>
  nmap <D-k> <M-k>
  vmap <D-j> <M-j>
  vmap <D-k> <M-k>
endif

" Delete trailing white space on save, useful for some filetypes ;)
fun! CleanExtraSpaces()
    let save_cursor = getpos(".")
    let old_query = getreg('/')
    silent! %s/\s\+$//e
    call setpos('.', save_cursor)
    call setreg('/', old_query)
endfun

if has("autocmd")
    " autocmd BufWritePre *.txt,*.js,*.py,*.wiki,*.sh,*.coffee :call CleanExtraSpaces()
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Misc
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" Toggle paste mode on and off
map <leader>pp :setlocal paste!<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Helper functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! CmdLine(str)
    call feedkeys(":" . a:str)
endfunction

function! VisualSelection(direction, extra_filter) range
    let l:saved_reg = @"
    execute "normal! vgvy"

    let l:pattern = escape(@", "\\/.*'$^~[]")
    let l:pattern = substitute(l:pattern, "\n$", "", "")

    if a:direction == 'gv'
        call CmdLine("ProjectRootExe CtrlSF \"" . l:pattern . "\" " )
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    endif

    let @/ = l:pattern
    let @" = l:saved_reg
endfunction
" end of amix/basic.vim

" Disable scrollbars (real hackers don't use scrollbars for navigation!)
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Turn persistent undo on
"    means that you can undo even when you close a buffer/VIM
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
try
    set undodir=~/.vim_runtime/temp_dirs/undodir
    set undofile
catch
endtry


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Command mode related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Smart mappings on the command line
cno $h e ~/
cno $d e ~/Desktop/
cno $j e ./
cno $c e <C-\>eCurrentFileDir("e")<cr>

" $q is super useful when browsing on the command line
" it deletes everything until the last slash
cno $q <C-\>eDeleteTillSlash()<cr>

" Bash like keys for the command line
cnoremap <C-A>		<Home>
cnoremap <C-E>		<End>
cnoremap <C-K>		<C-U>

cnoremap <C-P> <Up>
cnoremap <C-N> <Down>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Omni complete functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
" end of amix/extended.vim

execute pathogen#infect()
syntax on
filetype plugin indent on
set tw=90
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

" Python specific
autocmd FileType python set tw=0  " let the linter handle this

" JS specific
autocmd FileType javascript set tw=0  " let the linter handle this

map <leader>p "+p
vmap <leader>y "+y

nmap j gj
nmap k gk

" When you press gv with a selection, you ags the selected text
vnoremap <silent> gv :call VisualSelection('gv', '')<CR>

" When you press <leader>r you can search and replace the selected text
vnoremap <silent> <leader>r :call VisualSelection('replace', '')<CR>

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

""""""""""""""""""""""""""""""
" => Deoplete
""""""""""""""""""""""""""""""
let g:deoplete#enable_at_startup = 1


""""""""""""""""""""""""""""""
" => vim-prettier
""""""""""""""""""""""""""""""
let g:prettier#config#parser = 'typescript'
let g:prettier#config#semi = 'false'
let g:prettier#config#single_quote = 'true'
let g:prettier#config#bracket_spacing = 'false'


""""""""""""""""""""""""""""""
" => DelimitMate
""""""""""""""""""""""""""""""
au FileType python let b:delimitMate_nesting_quotes = ['"']
au FileType markdown let b:delimitMate_nesting_quotes = ['`']
" don't close < because we have vim-closetag for that
let delimitMate_matchpairs = "(:),[:],{:}"
let delimitMate_expand_space = 1
let delimitMate_expand_cr = 1
let delimitMate_expand_inside_quotes = 1


""""""""""""""""""""""""""""""
" => CTRL-P
""""""""""""""""""""""""""""""
" use ctrl+y to cancel popup
let g:ctrlp_working_path_mode = 'ra'

let g:ctrlp_map = '<C-f>'
map <C-b> :CtrlPBuffer<CR>
map <A-f> :CtrlPCurWD<CR>

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist|lcov-report|build)|(\.(swp|ico|git|svn|venv|DS_Store|pytest_cache|nuxt|cache|yarn))$'
let g:ctrlp_show_hidden = 1
let g:ctrlp_root_markers = ['package.json'] " might only want for certain projects


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
au FileType mako vmap Si S"i${ _(<esc>2f"a) }<esc>
xmap S <Plug>VSurround " prefer this over the conflicting yankstack mapping


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-yankstack
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" By default, yankstack adds only 2 key bindings, in normal and visual modes:
"
"     meta-p - cycle backward through your history of yanks
"     meta-shift-p - cycle forwards through your history of yanks
"
" After pasting some text using p or P, you can cycle through your yank history
" using these commands. Typing either of these keys without pasting first will do
" a normal paste (the same as typing p). This also works in insert mode.


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Vim-Airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Always show statusline
set laststatus=2
let g:airline#extensions#wordcount#enabled = 0
let g:airline#extensions#branch#enabled = 0
let g:airline#extensions#tagbar#enabled = 0
" remove B (version control) section
let g:airline#extensions#default#layout = [  [ 'a', 'c' ],  [ 'x', 'y', 'z', 'error', 'warning' ]  ]


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Snippets
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:UltiSnipsExpandTrigger="<c-e>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
let g:UltiSnipsEditSplit="vertical"


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
nmap <leader>/ <Plug>(caw:hatpos:toggle)
xmap <leader>/ <Plug>(caw:hatpos:toggle)


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => context_filetype.vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" needs to be run for context sensitive commenting to work, not sure why
autocmd VimEnter * silent echo context_filetype#get()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => ctrlsf.vim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>g :ProjectRootExe CtrlSF -C 1<space>
let g:ctrlsf_auto_focus = {
    \ "at": "done",
    \ "duration_less_than": 1000
    \ }


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => leaderf
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:Lf_WindowPosition = 'popup'
let g:Lf_PreviewInPopup = 1
let g:Lf_StlSeparator = { 'left': "\ue0b0", 'right': "\ue0b2", 'font': "DejaVu Sans Mono for Powerline" }
let g:Lf_PreviewResult = {'Function': 0, 'BufTag': 0 }

let g:Lf_ShortcutF = "<leader>fh" " fh for find-here because it's not from project root
noremap <leader>ff :<C-U><C-R>=printf("ProjectRootExe Leaderf file %s", "")<CR><CR>
noremap <leader>fb :<C-U><C-R>=printf("Leaderf buffer %s", "")<CR><CR>
noremap <leader>fm :<C-U><C-R>=printf("Leaderf mru %s", "")<CR><CR>
noremap <leader>fl :<C-U><C-R>=printf("Leaderf line %s", "")<CR><CR>

let g:Lf_CommandMap = {
      \ '<C-K>': ['<Up>'],
      \ '<C-J>': ['<Down>'],
      \ '<C-X>': ['<C-S>'],
      \ '<C-S>': ['<C-X>'],
      \ '<C-]>': ['<C-V>'],
      \ '<C-V>': ['<C-]>']
      \}

" FIXME look at ripgrep integration


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => rainbow_levels
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>l :RainbowLevelsToggle<cr>


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
  " autocmd FileType c,cpp,proto AutoFormatBuffer clang-format
  autocmd FileType go AutoFormatBuffer gofmt
  " autocmd FileType html,css,sass,scss,less,json AutoFormatBuffer js-beautify
  " autocmd FileType javascript,vue AutoFormatBuffer prettier
  autocmd FileType java AutoFormatBuffer google-java-format
  autocmd FileType python AutoFormatBuffer yapf
  " Alternative: autocmd FileType python AutoFormatBuffer autopep8
augroup END
" the glaive#Install() should go after the "call vundle#end()"
call glaive#Install()
" Enable codefmt's default mappings on the <Leader>= prefix.
Glaive codefmt plugin[mappings]

" consider moving config for prettier to a file (that is only used when we call
" the global prettier command) so we don't conflict with project specific
" settings
Glaive codefmt prettier_options=`['--single-quote', '--trailing-comma=all', '--arrow-parens=avoid', '--print-width=80', '--no-semi']`
" make sure your env has the following set:
"   export jsbeautify_indent_size=2


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => golden-ratio
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"  it makes NerdTree worse: makes it a bit wider, then locks it there and messes up other
"  windows... no good :(
" let g:golden_ratio_exclude_nonmodifiable = 1
"  https://github.com/Acelya-9028/golden-ratio/commit/da4491453ab859bced658edde296781ad23bae2e?diff=split
"  doesn't fix the problem either. I think the problem is the 'BufLeave' won't fire for
"  nerdtree, but the 'WinEnter' *will* fire for the other window you enter, which still
"  causes a resize on nerdtree.


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => vim-wordmotion
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" # let g:wordmotion_uppercase_spaces = ['\w\()\)\@='] | call wordmotion#reload()
" ```
" barBaz) {
" ```
" cW fails: leaves the last char before )
" ysW' works
" yW works
" E fails: cursor is on last 'a', should be on 'z'
" --------------------------
" ```
" barBaz ) {
" ```
" cW works
" ysW' works
" yW fails: includes space
" W works
" --------------------------
"
"
" # let g:wordmotion_uppercase_spaces = [')'] | call wordmotion#reload()
" ```
" barBaz) {
" ```
" cW works
" ysW' fails: includes )
" yW fails: includes ) space
" E works
" --------------------------
" ```
" barBaz ) {
" ```
" cW works
" ysW' fails: includes )
" yW fails: includes space ) space
" E works
" --------------------------
"
"
" # this is the default config for wordmotion
" # let g:wordmotion_uppercase_spaces = [] | call wordmotion#reload()
" ```
" barBaz) {
" ```
" cW fails: consumes the )
" ysW' fails: includes )
" yW fails: include ) and space
" E fail: cursor is on )
" --------------------------
" ```
" barBaz ) {
" ```
" cW works
" ysW' works
" yW fails: includes space
" E works
" --------------------------


" We need to do this to stop ft-sql from continually complaining with the error:
" SQLComplete: the dbext plugin must be loaded for dynamic sql completion
let g:omni_sql_no_default_maps = 1

function! Blame() range
  execute "normal! mz"
  execute "%!git blame %"
  redraw
  " sleep 100m
  echom "use z mark for line"
  " FIXME 'z doesn't work!
  execute "normal! 'z"
endfunction
