" NOTE: main vim config files here: /usr/share/vim/   DO NOT modify directly

" USEFUL http://nvie.com/posts/how-i-boosted-my-vim/
" USEFUL http://www.vim.org/scripts/script.php?script_id=302  << convert ANSI color codes into VIM color codes
" after it's installed use   :AnsiEsc  within vim to execute the script

if has("autocmd")
  " remember where I was in a file
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

  " except for git commits
  autocmd FileType gitcommit call setpos('.', [0, 1, 1, 0])
endif


" Turn on line#s and search highlighting
set ruler
set hlsearch

syntax on
" :scriptnames   to view the currently loaded syntax files

" Set the syntax highlighting to scan from the top of the file
" this prevents syntax from breaking midway through complex files
" more info here => :help syn-sync
"syn sync fromstart
"syn sync minlines=50
" note: these may not work here because a language syntax file might set them, and that would be loaded after vimrc
"command :syntime to troubleshoot syntax highlighting slowness

" Note - syntax highlighting for html.erb files is fixed here:
" ~/.vim/after/syntax/html.vim

" Syntax folders
" ~/.vim/syntax/
" ~/.vim/after/syntax/
" /usr/share/vim/vim82/syntax/

" This might be interesting
" turn hybrid line numbers on
":set number relativenumber

" NOTE : installed https://github.com/chrisbra/vim-diff-enhanced  plugin
" myers/default -- the default algo without the plugin
" minimal       -- myers but TRY harder
" patience      -- 
" histogram     -- patience but faster
" TO change on the fly use :EnhancedDiff <algorithm>

if &diff
    " we're in diff mode
    "set diffopt+=iwhite
    syntax off
    " TODO: DO NOT set ignore whitespace for python files

    " in theory this could work, but cannot get it to work: https://github.com/chrisbra/vim-diff-enhanced
endif

" turn off syntax highlight for README.md files
"au BufNewFile,BufRead * if expand('<afile>:e') !=? 'inc' | syntax enable | endif
autocmd BufRead,BufNewFile *.md set syntax=off

" shortcuts
command Q qall
command W wall

" convert tabs into spaces
set tabstop=2
set expandtab
" convert existing with :retab command

" Fix backspace so its not capped to start of the insert (for example)
set backspace=indent,eol,start

" space highlighting
hi NonText    ctermfg=253
hi SpecialKey ctermfg=253
set listchars=tab:→\ ,eol:↲,nbsp:␣,space:•,extends:⟩,precedes:⟨

"set list
" NOTE: don't have list on by default, because when copying out of vim, it'll grab the 'map character' instead of the original. Therefore the paste will be screwy

" Color demo
" :so ~/.vim/color_demo.vim

" Disable this garbage
" https://vim.fandom.com/wiki/Modeline_magic
set nomodeline

