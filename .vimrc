execute pathogen#infect()
" Make Vim more useful
set nocompatible
" Use the OS clipboard by default (on versions compiled with `+clipboard`)
"set clipboard=unnamed
" Enhance command-line completion
set wildmenu
" Allow cursor keys in insert mode
set esckeys
" Allow backspace in insert mode
set backspace=indent,eol,start
" Optimize for fast terminal connections
set ttyfast
" Add the g flag to search/replace by default
set gdefault
" Use UTF-8 without BOM
set encoding=utf-8 nobomb
" Change mapleader
let mapleader=","
" Don’t add empty newlines at the end of files
set binary
set noeol
" Centralize backups, swapfiles and undo history
set backupdir=~/.vim/backups
set directory=~/.vim/swaps
if exists("&undodir")
	set undodir=~/.vim/undo
endif

" Respect modeline in files
set modeline
set modelines=4
" Enable per-directory .vimrc files and disable unsafe commands in them
set exrc
set secure
" Enable line numbers
set number
" Enable syntax highlighting
syntax on
" Highlight current line
" set cursorline
" indent using two spaces
set shiftwidth=2
" Make tabs as wide as two spaces
set tabstop=2
" always expand tabs into spaces
set expandtab
set softtabstop=0
" Show “invisible” characters
" set lcs=tab:▸\ ,trail:·,eol:¬,nbsp:_
" set list
" Highlight searches
set hlsearch
" Ignore case of searches
set ignorecase
" Highlight dynamically as pattern is typed
set incsearch
" Always show status line
set laststatus=2
" Disable mouse in all modes
set mouse=""
" Disable error bells
set noerrorbells
" Show visual bells
set visualbell
" Don’t reset cursor to start of line when moving around.
set nostartofline
" Show the cursor position
set ruler
" Don’t show the intro message when starting Vim
set shortmess=atI
" Show the current mode
set showmode
" Show the filename in the window titlebar
set title
set titleold=""
" Show the (partial) command as it’s being typed
set showcmd
" Don't use relative line numbers
if exists("&relativenumber")
	set norelativenumber
"	au BufReadPost * set relativenumber
endif
" Start scrolling three lines before the horizontal window border
set scrolloff=3
" Set key to toggle paste mode
set pastetoggle=<F11>

" Strip trailing whitespace (,ss)
function! StripWhitespace()
	let save_cursor = getpos(".")
	let old_query = getreg('/')
	:%s/\s\+$//e
	call setpos('.', save_cursor)
	call setreg('/', old_query)
endfunction
noremap <leader>ss :call StripWhitespace()<CR>
" Save a file as root (,W)
noremap <leader>W :w !sudo tee % > /dev/null<CR>

" Automatic commands
if has("autocmd")
	" Enable file type detection
	filetype on
	" Treat .json files as .js
	autocmd BufNewFile,BufRead *.json setfiletype json syntax=javascript
	autocmd BufEnter * let &titlestring = $HOSTNAME . ":" . expand("%:p:~")
  autocmd FileType make setlocal noexpandtab
endif

" Colours
if has('gui_running')
  set background=light
else
  set background=dark
endif
colorscheme solarized
set rtp+=/usr/lib/python2.7/site-packages/Powerline-beta-py2.7.egg/powerline/bindings/vim
" Hide the default mode text (e.g. -- INSERT -- below the statusline)
set noshowmode

if &term == "xterm" || &term == "vt220" || &term == "xterm-256color"
  " Let the title stuff work even if we don't open the DISPLAY
  set title
  set t_ts=]2;
  set t_fs= 
endif

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 1

let g:syntastic_enable_perl_checker = 1
let g:syntastic_python_checkers = ['flake8']
let g:syntastic_sh_shellcheck_args="-x"

" run terraform fmt on save
let g:terraform_fmt_on_save = 1
