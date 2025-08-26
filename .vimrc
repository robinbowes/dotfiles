" Use bash from the path (/bin/bash is 3.x on MacOS)
set shell=/usr/bin/env\ bash

" Use native vim packages (requires vim 8+)
packloadall

" ------------------------------------------------------
" set in vim-sensible

" Make Vim more useful
" set nocompatible

" Allow backspace in insert mode
"set backspace=indent,eol,start

" Highlight dynamically as pattern is typed
" set incsearch

" Always show status line
" set laststatus=2

" Show the cursor position
" set ruler

" Enhance command-line completion
" set wildmenu

" Start scrolling three lines before the horizontal window border
" set scrolloff=3

" Enable syntax highlighting
" syntax on
" ------------------------------------------------------

" Use the OS clipboard by default (on versions compiled with `+clipboard`)
"set clipboard=unnamed

" Allow cursor keys in insert mode
if !has('nvim')
  set esckeys
endif

" Optimize for fast terminal connections
set ttyfast

" Add the g flag to search/replace by default
set gdefault

" Use UTF-8 without BOM
set encoding=utf-8 nobomb

" Change mapleader
let mapleader=","

" Add empty newlines at the end of files
set binary
set eol

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

" Disable mouse in all modes
set mouse=""

" Disable error bells
set noerrorbells

" Show visual bells
set visualbell

" Don’t reset cursor to start of line when moving around.
set nostartofline

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
  " Add formatting command for python files
  autocmd FileType python nnoremap <leader>y :0,$!black<Cr><C-o>
endif

" Colours
if has('gui_running')
  set background=light
else
  set background=dark
endif

colorscheme solarized

" Hide the default mode text (e.g. -- INSERT -- below the statusline)
set noshowmode

if &term == "xterm" || &term == "vt220" || &term == "xterm-256color"
  " Let the title stuff work even if we don't open the DISPLAY
  set title
  set t_ts=]2;
  set t_fs=
endif

" run terraform fmt on save
let g:terraform_fmt_on_save = 1

" enable docstring preview in SimpylFold (python files)
let g:SimpylFold_docstring_preview = 1

" Go config
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'

" airline config
AirlineTheme solarized
let g:airline_solarized_bg='dark'

" ALE config
" Note: we reply on editorconfig to do whitepace fixes
let g:ale_fixers = {
  \ 'markdown': ['prettier'],
  \ 'python': ['ruff', 'ruff_format'],
  \ 'sh': ['shfmt']
  \}

let g:ale_linters = {
  \ 'markdown': ['prettier'],
  \ 'go': ['gopls'],
  \ 'perl': ['perl','perlcritic'],
  \ 'python': ['ruff'],
  \ 'sh': ['shellcheck']
  \}

"let g:ale_python_flake8_options = '--max-line-length 88 --extend-ignore E203'
let g:ale_python_ruff_use_global = 1
let g:ale_python_ruff_options = '--extend-select I'
let g:ale_fix_on_save = 1
let g:ale_floating_preview = 1
let g:ale_sign_error = ' ✖'
let g:ale_sign_warning = ' •'

" lint and formatting options for shell files
let g:ale_sh_shellcheck_options = '-x'
let g:ale_sh_shfmt_options = '-i2 -bn -ci -sr'

" lint and formatting options for d2 files
" Enable/disable auto format on save (default: 1)
let g:d2_fmt_autosave = 1
" Customize the format command (default: "d2 fmt")
let g:d2_fmt_command = "d2 fmt"
" Fail silently when formatting fails (default: 0)
let g:d2_fmt_fail_silently = 0
" Enable/disable auto validate on save (default: 0)
let g:d2_validate_autosave = 0
" Customize the validate command (default: "d2 validate")
let g:d2_validate_command = "d2 validate"
" Use quickfix or locationlist for errors (default: "quickfix")
let g:d2_list_type = "quickfix"
" Fail silently when validation fails (default: 0)
let g:d2_validate_fail_silently = 0

" fzf integration
set rtp+=/usr/local/opt/fzf
