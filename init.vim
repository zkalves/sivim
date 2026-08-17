" Use before config if available {
    if filereadable(expand("~/.sivim/config/init.before.vim"))
        source ~/.sivim/config/init.before.vim
    endif
" }

"" Plugin manager {
    call plug#begin('~/.sivim/plugged')
"        " Declare the list of plugins.
        Plug 'altercation/vim-colors-solarized'    " Default colorscheme
        Plug 'godlygeek/tabular'                   " Text alignment
        Plug 'nathanaelkane/vim-indent-guides'     " Visually display indent levels
        Plug 'tmhedberg/SimpylFold'                " Code folding for python
        Plug 'tpope/vim-fugitive'                  " Git wrapper
        Plug 'tpope/vim-sensible'                  " Basic configs
        Plug 'itchyny/lightline.vim'               " statusline
        Plug 'dense-analysis/ale'                  " Async lint engine (replaces syntastic)
        Plug 'maximbaz/lightline-ale'              " Show ALE status in lightline
        Plug 'easymotion/vim-easymotion'           " Move easier through the code
        Plug 'christoomey/vim-tmux-navigator'
        Plug 'tmux-plugins/vim-tmux-focus-events'
        Plug 'tmux-plugins/vim-tmux'
        " Verilog plugins
        Plug 'vhda/verilog_systemverilog.vim'

        " Yank/paste ring: Neovim gets the actively maintained Lua plugin,
        " plain Vim falls back to nvim-miniyank (upstream unmaintained since
        " 2019 but still functional for basic use)
        if has('nvim')
            Plug 'gbprod/yanky.nvim'
        else
            Plug 'bfredl/nvim-miniyank'
        endif

        " Commenting: Neovim gets the actively maintained Lua plugin,
        " plain Vim uses the maintained nerdcommenter fork (upstream
        " scrooloose/nerdcommenter is no longer maintained)
        if has('nvim')
            Plug 'numToStr/Comment.nvim'
        else
            Plug 'preservim/nerdcommenter'
        endif

    " Initialize plugin system
    call plug#end()
"" }

" General {
    " Allow to trigger background
    function! ToggleBG()
        let s:color_name = g:colors_name
        let s:tbg = &background
        " Inversion
        if s:tbg == "dark"
            set background=light
        else
            set background=dark
        endif
    endfunction

    set mouse=a                 " Automatically enable mouse usage
    set mousehide               " Hide the mouse cursor while typing
    scriptencoding utf-8

    if has('clipboard')
        if has('unnamedplus')  " When possible use + register for copy-paste
            set clipboard=unnamed,unnamedplus
        else         " On mac and Windows, use * register for copy-paste
            set clipboard=unnamed
        endif
    endif

    " Most prefer to automatically switch to the current file directory when
    " a new buffer is opened; to prevent this behavior, add the following to
    " your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_autochdir = 1
    if !exists('g:sivim_no_autochdir')
        autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif
        " Always switch to the current file directory
    endif

    "set autowrite                       " Automatically write a file when leaving a modified buffer
    set shortmess+=filmnrxoOtT          " Abbrev. of messages (avoids 'hit enter')
    set viewoptions=folds,options,cursor,unix,slash " Better Unix / Windows compatibility
    set virtualedit=onemore             " Allow for cursor beyond last character
    set spell                           " Spell checking on
    set hidden                          " Allow buffer switching without saving
    set iskeyword-=.                    " '.' is an end of word designator
    set iskeyword-=#                    " '#' is an end of word designator
    set iskeyword-=-                    " '-' is an end of word designator
    set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace

    " Instead of reverting the cursor to the last position in the buffer, we
    " set it to the first line when editing a git commit message
    autocmd FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])

    " http://vim.wikia.com/wiki/Restore_cursor_to_file_position_in_previous_editing_session
    " Restore cursor to file position in previous editing session
    " To disable this, add the following to your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_restore_cursor = 1
    if !exists('g:sivim_no_restore_cursor')
        function! ResCur()
            if line("'\"") <= line("$")
                silent! normal! g`"
                return 1
            endif
        endfunction

        augroup resCur
            autocmd!
            autocmd BufWinEnter * call ResCur()
        augroup END
    endif

    " Ignore whitespaces for diff
    set diffopt+=iwhite

    " Setting up the directories {
        set backup                  " Backups are nice ...
        if has('persistent_undo')
            set undofile                " So is persistent undo ...
            set undolevels=1000         " Maximum number of changes that can be undone
            set undoreload=10000        " Maximum number lines to save for undo on a buffer reload
        endif

        " To disable views add the following to your ~/.sivim/config/init.before.vim file:
        "   let g:sivim_no_views = 1
        if !exists('g:sivim_no_views')
            " Add exclusions to mkview and loadview
            " eg: *.*, svn-commit.tmp
            let g:skipview_files = [
                \ '\[example pattern\]'
                \ ]
        endif
    " }

" }

" Formatting {

    set nowrap                      " Do not wrap long lines
    set expandtab                   " Tabs are spaces, not tabs
    set tabstop=2                   " An indentation every two columns
    set softtabstop=2               " Let backspace delete indent
    set shiftwidth=2                " Use indents of 2 spaces
    set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
    set splitright                  " Puts new vsplit windows to the right of the current
    set splitbelow                  " Puts new split windows to the bottom of the current
    "set matchpairs+=<:>             " Match, to be used with %
    set pastetoggle=<F12>           " pastetoggle (sane indentation on pastes)
    "set comments=sl:/*,mb:*,elx:*/  " auto format comment blocks
    " Remove trailing whitespaces and ^M chars
    " To disable the stripping of whitespace, add the following to your
    " ~/.sivim/config/init.before.vim file:
    "   let g:sivim_keep_trailing_whitespace = 1
    autocmd FileType c,cpp,java,go,php,javascript,puppet,python,rust,twig,xml,yml,perl,sql,verilog,systemverilog autocmd BufWritePre <buffer> if !exists('g:sivim_keep_trailing_whitespace') | call StripTrailingWhitespace() | endif
    "autocmd FileType go autocmd BufWritePre <buffer> Fmt

    " Flag unnecessary whitespace
    highlight BadWhitespace ctermbg=red guibg=darkred
    autocmd BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

    autocmd BufRead,BufNewFile *.svh,*.svi set syntax=systemverilog
" }

" Key (re)Mappings {

    " The default leader is '\', but many people prefer ',' as it's in a standard
    " location. To override this behavior and set it back to '\' (or any other
    " character) add the following to your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_leader='\'
    if !exists('g:sivim_leader')
        let mapleader = ','
    else
        let mapleader=g:sivim_leader
    endif
    if !exists('g:sivim_localleader')
        let maplocalleader = '_'
    else
        let maplocalleader=g:sivim_localleader
    endif

    " List and change buffer
    nnoremap <leader>ls :ls<CR>:b

    " Change background color
    noremap <leader>bg :call ToggleBG()<CR>

    " The default mappings for editing and applying the sivim configuration
    " are <leader>ev and <leader>sv respectively. Change them to your preference
    " by adding the following to your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_edit_config_mapping='<leader>ec'
    "   let g:sivim_apply_config_mapping='<leader>sc'
    if !exists('g:sivim_edit_config_mapping')
        let s:sivim_edit_config_mapping = '<leader>ec'
    else
        let s:sivim_edit_config_mapping = g:sivim_edit_config_mapping
    endif
    if !exists('g:sivim_apply_config_mapping')
        let s:sivim_apply_config_mapping = '<leader>sc'
    else
        let s:sivim_apply_config_mapping = g:sivim_apply_config_mapping
    endif

    " Easier moving in tabs and windows
    " The lines conflict with the default digraph mapping of <C-K>
    " If you prefer that functionality, add the following to your
    " ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_easyWindows = 1
    if !exists('g:sivim_no_easyWindows')
        " Tmux
        if exists ('$TMUX')
            function! TmuxOrSplitSwitch(wincmd, tmuxdir)
                let previous_winnr = winnr()
                silent! execute "wincmd " . a:wincmd
                if previous_winnr == winnr()
                    call system("tmux select-pane -" . a:tmuxdir)
                    redraw!
                endif
            endfunction

            let previous_title = substitute(system("tmux display-message -p '#{pane_title}'"), '\n', '', '')
            let &t_ti = "\<Esc>]2;vim\<Esc>\\" . &t_ti
            let &t_te = "\<Esc>]2;". previous_title . "\<Esc>\\" . &t_te

            nnoremap <silent> <C-h> :call TmuxOrSplitSwitch('h', 'L')<cr>
            nnoremap <silent> <C-j> :call TmuxOrSplitSwitch('j', 'D')<cr>
            nnoremap <silent> <C-k> :call TmuxOrSplitSwitch('k', 'U')<cr>
            nnoremap <silent> <C-l> :call TmuxOrSplitSwitch('l', 'R')<cr>
        else
            map <C-h> <C-w>h
            map <C-j> <C-w>j
            map <C-k> <C-w>k
            map <C-l> <C-w>l
            "map <C-h> <C-W><C-h>
            "map <C-j> <C-W><C-j>
            "map <C-k> <C-W><C-k>
            "map <C-l> <C-W><C-l>
            "nnoremap <C-J> <C-W><C-J>
            "nnoremap <C-K> <C-W><C-K>
            "nnoremap <C-L> <C-W><C-L>
            "nnoremap <C-H> <C-W><C-H>
        endif
    endif

    " Wrapped lines goes down/up to next row, rather than next line in file.
    noremap j gj
    noremap k gk

    " End/Start of line motion keys act relative to row/wrap width in the
    " presence of `:set wrap`, and relative to line for `:set nowrap`.
    " Default vim behaviour is to act relative to text line in both cases
    " If you prefer the default behaviour, add the following to your
    " ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_wrapRelMotion = 1
    if !exists('g:sivim_no_wrapRelMotion')
        " Same for 0, home, end, etc
        function! WrapRelativeMotion(key, ...)
            let vis_sel=""
            if a:0
                let vis_sel="gv"
            endif
            if &wrap
                execute "normal!" vis_sel . "g" . a:key
            else
                execute "normal!" vis_sel . a:key
            endif
        endfunction

        " Map g* keys in Normal, Operator-pending, and Visual+select
        noremap $ :call WrapRelativeMotion("$")<CR>
        noremap <End> :call WrapRelativeMotion("$")<CR>
        noremap 0 :call WrapRelativeMotion("0")<CR>
        noremap <Home> :call WrapRelativeMotion("0")<CR>
        noremap ^ :call WrapRelativeMotion("^")<CR>
        " Overwrite the operator pending $/<End> mappings from above
        " to force inclusive motion with :execute normal!
        onoremap $ v:call WrapRelativeMotion("$")<CR>
        onoremap <End> v:call WrapRelativeMotion("$")<CR>
        " Overwrite the Visual+select mode mappings from above
        " to ensure the correct vis_sel flag is passed to function
        vnoremap $ :<C-U>call WrapRelativeMotion("$", 1)<CR>
        vnoremap <End> :<C-U>call WrapRelativeMotion("$", 1)<CR>
        vnoremap 0 :<C-U>call WrapRelativeMotion("0", 1)<CR>
        vnoremap <Home> :<C-U>call WrapRelativeMotion("0", 1)<CR>
        vnoremap ^ :<C-U>call WrapRelativeMotion("^", 1)<CR>
    endif

    " The following two lines conflict with moving to top and
    " bottom of the screen
    " If you prefer that functionality, add the following to your
    " ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_fastTabs = 1
    if !exists('g:sivim_no_fastTabs')
        map <S-H> gT
        map <S-L> gt
    endif

    " Stupid shift key fixes
    if !exists('g:sivim_no_keyfixes')
        if has("user_commands")
            command! -bang -nargs=* -complete=file E e<bang> <args>
            command! -bang -nargs=* -complete=file W w<bang> <args>
            command! -bang -nargs=* -complete=file Wq wq<bang> <args>
            command! -bang -nargs=* -complete=file WQ wq<bang> <args>
            command! -bang Wa wa<bang>
            command! -bang WA wa<bang>
            command! -bang Q q<bang>
            command! -bang QA qa<bang>
            command! -bang Qa qa<bang>
        endif

        cmap Tabe tabe
    endif

    " Yank from the cursor to the end of the line, to be consistent with C and D.
    nnoremap Y y$

    " Code folding options
    nmap <leader>f0 :set foldlevel=0<CR>
    nmap <leader>f1 :set foldlevel=1<CR>
    nmap <leader>f2 :set foldlevel=2<CR>
    nmap <leader>f3 :set foldlevel=3<CR>
    nmap <leader>f4 :set foldlevel=4<CR>
    nmap <leader>f5 :set foldlevel=5<CR>
    nmap <leader>f6 :set foldlevel=6<CR>
    nmap <leader>f7 :set foldlevel=7<CR>
    nmap <leader>f8 :set foldlevel=8<CR>
    nmap <leader>f9 :set foldlevel=9<CR>

    " Enable folding with the spacebar
    nnoremap <space> za

    " Most prefer to toggle search highlighting rather than clear the current
    " search results. To clear search highlighting rather than toggle it on
    " and off, add the following to your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_clear_search_highlight = 1
    if exists('g:sivim_clear_search_highlight')
        nmap <silent> <leader>/ :nohlsearch<CR>
    else
        nmap <silent> <leader>/ :set invhlsearch<CR>
    endif

    " Shortcuts

    " Visual shifting (does not exit Visual mode)
    vnoremap < <gv
    vnoremap > >gv

    " Allow using the repeat operator with a visual selection (!)
    " http://stackoverflow.com/a/8064607/127816
    vnoremap . :normal .<CR>

    " For when you forget to sudo.. Really Write the file.
    cmap w!! w !sudo tee % >/dev/null

    " Some helpers to edit mode
    " http://vimcasts.org/e/14
    cnoremap %% <C-R>=fnameescape(expand('%:h')).'/'<cr>
    map <leader>ew :e %%
    map <leader>es :sp %%
    map <leader>ev :vsp %%
    map <leader>et :tabe %%

    " Adjust viewports to the same size
    map <Leader>= <C-w>=

    " Map <Leader>ff to display all lines with keyword under cursor
    " and ask which one to jump to
    nmap <Leader>ff [I:let nr = input("Which one: ")<Bar>exe "normal " . nr ."[\t"<CR>

    " Easier horizontal scrolling
    map zl zL
    map zh zH

    " Vertical scroll to next non whitespace character
    nnoremap cd /\%<C-R>=virtcol(".")<CR>v\S<CR>
    nnoremap cu ?\%<C-R>=virtcol(".")<CR>v\S<CR>

    " Easier formatting
    nnoremap <silent> <leader>q gwip

    " Execute current line or current selection as Vim EX commands.
    nnoremap <leader>ee :exe getline(".")<CR>
    vnoremap <leader>ee :<C-w>exe join(getline("'<","'>"),'<Bar>')<CR>

    " Disable highlight when <leader><cr> is pressed
    nmap <silent> <leader><cr> :noh<cr>
    " Useful mappings for managing tabs
    nmap <leader>te :Te<cr>
    nmap <leader>tn :tabnew<cr>
    nmap <leader>to :tabonly<cr>
    nmap <leader>tc :tabclose<cr>
    nmap <leader>tm :tabmove
    nmap <leader>tv :tabe $MYVIMRC<cr>

    " Swap from horizontal to vertical split and viceversa
    nmap <leader>th <C-w>t<C-w>H
    nmap <leader>tk <C-w>t<C-w>K

    " SOS mappings
    nmap <Leader>sco :!soscmd co %<cr>
    nmap <Leader>scn :!soscmd co -Nlock %<cr>
    nmap <Leader>sci :!soscmd ci %<cr>
    nmap <Leader>sdi :!soscmd discardco %<cr>
    nmap <Leader>sdf :!soscmd discardco -F %<cr>

    " Search error messages
    nmap <Leader>e /\*E<cr>
    nmap <Leader>w /\*W<cr>
    "nmap <Leader>ue /^UVM_ERROR<cr>
    nmap <Leader>ue gg/^UVM_ERROR<CR>/@\s\=\d\+<CR>wvey:noh<CR>0
    nmap <Leader>uw /^UVM_WARNING<cr>
    " Go to start of sim
    nmap <Leader>gs gg/ncsim> run<CR>zt:noh<CR>

    " Remove the Windows ^M - when the encodings gets messed up
    nnoremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

    " Reverse string
    vnoremap <Leader>rv c<C-O>:set revins<CR><C-R>"<Esc>:set norevins<CR>

    " Retab from 8 spaces tabs to 3 whitespaces
    nmap <leader>rt :set tabstop=8 <bar> :retab <bar> :set tabstop=2 <cr>

    " Disable F1 help
    nmap <F1> <nop>

    " Yank/paste ring
    if has('nvim')
        map p <Plug>(YankyPutAfter)
        map P <Plug>(YankyPutBefore)
        nmap <c-n> <Plug>(YankyCycleForward)
        nmap <c-p> <Plug>(YankyCycleBackward)
    else
        map p <Plug>(miniyank-autoput)
        map P <Plug>(miniyank-autoPut)
    endif

    " Trim whitespaces
    nmap <leader>w :call StripTrailingWhitespace()<CR>

    " linediff
    noremap \ldt :Linediff<CR>
    noremap \ldo :LinediffReset<CR>
" }

" Plugin configuration {
    " Tabularize {
        if isdirectory(expand("~/.sivim/plugged/tabular"))
            command! -range AlignBrackets
              \ execute <line1>.','.<line2>.'Tabularize /('
              \ | execute <line1>.','.<line2>.'Tabularize /.*\zs)/l1l0'

            nmap <Leader>a& :Tabularize /&<CR>
            vmap <Leader>a& :Tabularize /&<CR>
            nmap <Leader>a= :Tabularize /^[^=]*\zs=<CR>
            vmap <Leader>a= :Tabularize /^[^=]*\zs=<CR>
            nmap <Leader>a=> :Tabularize /=><CR>
            vmap <Leader>a=> :Tabularize /=><CR>
            nmap <Leader>a: :Tabularize /:<CR>
            vmap <Leader>a: :Tabularize /:<CR>
            nmap <Leader>a:: :Tabularize /:\zs<CR>
            vmap <Leader>a:: :Tabularize /:\zs<CR>
            nmap <Leader>a, :Tabularize /,<CR>
            vmap <Leader>a, :Tabularize /,<CR>
            nmap <Leader>a,, :Tabularize /,\zs<CR>
            vmap <Leader>a,, :Tabularize /,\zs<CR>
            nmap <Leader>a<Bar> :Tabularize /<Bar><CR>
            vmap <Leader>a<Bar> :Tabularize /<Bar><CR>
            nmap <Leader>a( :Tabularize /(<CR>
            vmap <Leader>a( :Tabularize /(<CR>
            nmap <Leader>a) :Tabularize /.*\zs)/l1l0<CR>
            vmap <Leader>a) :Tabularize /.*\zs)/l1l0<CR>
            nmap <Leader>ab :AlignBrackets<CR>
            vmap <Leader>ab :AlignBrackets<CR>

        endif
    " }

"    " Fugitive {
"        if isdirectory(expand("~/.sivim/plugged/vim-fugitive"))
"            nnoremap <silent> <leader>gs :Gstatus<CR>
"            nnoremap <silent> <leader>gd :Gdiff<CR>
"            nnoremap <silent> <leader>gc :Gcommit<CR>
"            nnoremap <silent> <leader>gb :Gblame<CR>
"            nnoremap <silent> <leader>gl :Glog<CR>
"            nnoremap <silent> <leader>gp :Git push<CR>
"            nnoremap <silent> <leader>gr :Gread<CR>
"            nnoremap <silent> <leader>gw :Gwrite<CR>
"            nnoremap <silent> <leader>ge :Gedit<CR>
"            " Mnemonic _i_nteractive
"            nnoremap <silent> <leader>gi :Git add -p %<CR>
"            nnoremap <silent> <leader>gg :SignifyToggle<CR>
"        endif
"    "}

    " indent_guides {
        if isdirectory(expand("~/.sivim/plugged/vim-indent-guides/"))
            let g:indent_guides_start_level = 2
            let g:indent_guides_guide_size = 1
            let g:indent_guides_enable_on_vim_startup = 0
        endif
    " }

    "" lightline {
        set laststatus=2
        set noshowmode
    "" }

    " ALE (replaces syntastic) {
        let g:ale_lint_on_text_changed = 'normal'
        let g:ale_lint_on_insert_leave = 1
        let g:ale_sign_column_always = 1

        " Python: pip install --user 'python-lsp-server[all]' pulls in
        " flake8 (pyflakes + pycodestyle + mccabe) and pylint as CLI tools;
        " ALE calls them directly, no LSP client/server needed.
        let g:ale_linters = { 'python': ['flake8', 'pylint'] }

        " lightline-ale: show ALE status in the statusline
        let g:lightline#ale#indicator_checking = "•••"
        let g:lightline#ale#indicator_infos = "ℹ"
        let g:lightline#ale#indicator_warnings = "⚠"
        let g:lightline#ale#indicator_errors = "✗"
        let g:lightline#ale#indicator_ok = "✓"

        let g:lightline = {
            \ 'active': {
            \   'right': [ [ 'lineinfo' ],
            \              [ 'percent' ],
            \              [ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ] ]
            \ },
            \ 'component_expand': {
            \   'linter_checking': 'lightline#ale#checking',
            \   'linter_infos': 'lightline#ale#infos',
            \   'linter_warnings': 'lightline#ale#warnings',
            \   'linter_errors': 'lightline#ale#errors',
            \   'linter_ok': 'lightline#ale#ok',
            \ },
            \ 'component_type': {
            \   'linter_checking': 'right',
            \   'linter_infos': 'right',
            \   'linter_warnings': 'warning',
            \   'linter_errors': 'error',
            \   'linter_ok': 'right',
            \ },
            \ }
    " }

    " Yank/paste ring {
        if has('nvim')
            lua pcall(function() require('yanky').setup() end)
        endif
    " }

    " Commenting {
        if has('nvim')
            lua pcall(function() require('Comment').setup() end)
        endif
    " }
"}

" Vim UI {

    " Set colorscheme {
        set background=dark
        colorscheme solarized
    " }

    set cursorline                  " Highlight current line

    highlight clear SignColumn      " SignColumn should match background
    highlight clear LineNr          " Current line number row will have same background color in relative mode
    "highlight clear CursorLineNr    " Remove highlight color from current line number

    set linespace=0                 " No extra spaces between rows
    set number                      " Line numbers on
    set relativenumber              " Relative line numbers on
    set showmatch                   " Show matching brackets/parenthesis
    set hlsearch                    " Highlight search terms
    set winminheight=0              " Windows can be 0 line high
    set ignorecase                  " Case insensitive search
    set smartcase                   " Case sensitive when uc present
    set wildmenu                    " Show list instead of just completing
    set wildmode=list:longest,full  " Command <Tab> completion, list matches, then longest common part, then all.
    set whichwrap=b,s,h,l,<,>,[,]   " Backspace and cursor keys wrap too
    set scrolljump=5                " Lines to scroll when cursor leaves screen
    set foldenable                  " Auto fold code
    set foldmethod=syntax           " Enable folding
    set foldlevel=99
    set list

    augroup numbertoggle
        autocmd!
        autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
        autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
    augroup END
" }

" Functions {

    " Initialize directories {
    function! InitializeDirectories()
        let parent = $HOME . '/.sivim'
        let prefix = 'vim'
        let dir_list = {
                    \ 'backup': 'backupdir',
                    \ 'views': 'viewdir',
                    \ 'swap': 'directory' }

        if has('persistent_undo')
            let dir_list['undo'] = 'undodir'
        endif

        " To specify a different directory in which to place the vimbackup,
        " vimviews, vimundo, and vimswap files/directories, add the following to
        " your .sivim/config/init.before.vim file:
        "   let g:sivim_consolidated_directory = <full path to desired directory>
        "   eg: let g:sivim_consolidated_directory = $HOME . '/.sivim/'
        if exists('g:sivim_consolidated_directory')
            let common_dir = g:sivim_consolidated_directory . prefix
        else
            let common_dir = parent . '/' . prefix
        endif

        for [dirname, settingname] in items(dir_list)
            let directory = common_dir . dirname . '/'
            if exists("*mkdir")
                if !isdirectory(directory)
                    call mkdir(directory)
                endif
            endif
            if !isdirectory(directory)
                echo "Warning: Unable to create backup directory: " . directory
                echo "Try: mkdir -p " . directory
            else
                let directory = substitute(directory, " ", "\\\\ ", "g")
                exec "set " . settingname . "=" . directory
            endif
        endfor
    endfunction
    call InitializeDirectories()
    " }

    " Strip whitespace {
    function! StripTrailingWhitespace()
        " Preparation: save last search, and cursor position.
        let _s=@/
        let l = line(".")
        let c = col(".")
        " do the business:
        %s/\s\+$//e
        " clean up: restore previous search history, and cursor position
        let @/=_s
        call cursor(l, c)
    endfunction
    " }

    " Shell command {
    function! s:RunShellCommand(cmdline)
        botright new

        setlocal buftype=nofile
        setlocal bufhidden=delete
        setlocal nobuflisted
        setlocal noswapfile
        setlocal nowrap
        setlocal filetype=shell
        setlocal syntax=shell

        call setline(1, a:cmdline)
        call setline(2, substitute(a:cmdline, '.', '=', 'g'))
        execute 'silent $read !' . escape(a:cmdline, '%#')
        setlocal nomodifiable
        1
    endfunction

    command! -complete=file -nargs=+ Shell call s:RunShellCommand(<q-args>)
    " e.g. Grep current file for <search_term>: Shell grep -Hn <search_term> %
    " }

    " Edit and source config files {
    function! s:ExpandFilenameAndExecute(command, file)
        execute a:command . " " . expand(a:file, ":p")
    endfunction

    function! s:EditSiVimConfig()
        call <SID>ExpandFilenameAndExecute("tabedit", "~/.sivim/init.vim")

        execute bufwinnr(".sivim/init.vim") . "wincmd w"

        call <SID>ExpandFilenameAndExecute("vsplit", "~/.sivim/config/init.before.vim")
        wincmd l
        call <SID>ExpandFilenameAndExecute("split", "~/.sivim/config/init.after.vim")

        execute bufwinnr("~/.sivim/config/init.before.vim") . "wincmd w"
    endfunction

    execute "noremap " . s:sivim_edit_config_mapping "    :call <SID>EditSiVimConfig()<CR>"
    execute "noremap " . s:sivim_apply_config_mapping . " :source $MYVIMRC<CR>"
    " }
" }

" Use after config if available {
    if filereadable(expand("~/.sivim/config/init.after.vim"))
        source ~/.sivim/config/init.after.vim
    endif
" }

" Modeline  {
" vim: set sw=4 ts=8 sts=4 et tw=78 foldmarker={,} foldlevel=0 foldmethod=marker spell:
"
" }
