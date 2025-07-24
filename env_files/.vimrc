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
" /usr/share/vim/vim91/syntax/

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

" shortcuts (REM: all must start with an uppercase letter)
command Q qall
command W wall
" for consistency should I use wallqall?
command WQ wqall

" convert tabs into spaces
set tabstop=2
set expandtab
" convert existing with :retab command

" Fix backspace so its not capped to start of the insert (for example)
set backspace=indent,eol,start

" (optional) automatically indent to the same level as the previous line when inserting a new line
set autoindent

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

" vim syntax tries to be intelligent about which actual shell you're running.
" for ubuntu /bin/sh =>symlinked=> dash
" for macos /bin/sh =>system_setting=> whatever shell
" vim isn't smart enough to decypher macos, so just force it
let g:is_dash = 1

" Remember that in vim:
"   y => yank   => copy (ish)
"   d => delete => cut (ish)
"   p => put    => paste (ish)
"   c => change => delete (ish)
" These all use internal registers not the system clipboard (unless configured to do so? see below)

" Fix clipboard for OSX - allows yy (copy) & dd (cut) to work
" TODO: why did I want this?
"if system('uname -s') == 'Darwin\n'
"  set clipboard=unnamed "OSX
"else
"  set clipboard=unnamedplus "Linux
"endif

" Understanding remappings: https://stackoverflow.com/a/3776182/6716352
" Add shorthands to just delete a line without cutting it (and overwritting the clipboard)
" see: https://stackoverflow.com/a/11993928/6716352
" \d in normal modes - throw away the text, don't cut it
"nnoremap <leader>d "_d
" same for visual
"xnoremap <leader>d "_d
" \p in visual mode - throw away the current line and replace it with clipboard
"nnoremap <leader>p "_d$p

" maybe use 'C' to delete from the cursor position to the end of the line?
" it seems like c (delete) and d (cut) are opposite meanings?
" TODO: maybe I should change my own internal bindings to flip these?


