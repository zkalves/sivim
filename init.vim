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
        Plug 'tpope/vim-obsession'                 " Session tracking, read by tmux-resurrect
        Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }
        " Verilog plugins
        Plug 'vhda/verilog_systemverilog.vim'

        " Yank/paste ring: Neovim 0.9+ gets the actively maintained Lua
        " plugin, anything older falls back to nvim-miniyank (upstream
        " unmaintained since 2019 but still functional for basic use).
        let s:have_yanky = has('nvim-0.9')
        if s:have_yanky
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

    " vim-tmux-navigator claims <C-h/j/k/l> and <C-\>. init.before.vim has
    " already been sourced, so honour its opt-out before the plugin maps them.
    if exists('g:sivim_no_easyWindows')
        let g:tmux_navigator_no_mappings = 1
    endif

    " Write the buffer when leaving the pane, so a simulation launched in the
    " neighbouring shell picks up the edit.
    let g:tmux_navigator_save_on_switch = 1

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

    " On a login node reached over plain ssh there is no X display, so the
    " usual xsel/xclip providers are unavailable. Route the registers through
    " the tmux buffer instead; .tmux.conf has set-clipboard on, which forwards
    " it to the local terminal over OSC 52.
    if !empty($TMUX) && empty($DISPLAY) && executable('tmux')
        let g:clipboard = {
            \ 'name': 'tmux',
            \ 'copy': {
            \   '+': ['tmux', 'load-buffer', '-w', '-'],
            \   '*': ['tmux', 'load-buffer', '-w', '-'],
            \ },
            \ 'paste': {
            \   '+': ['tmux', 'save-buffer', '-'],
            \   '*': ['tmux', 'save-buffer', '-'],
            \ },
            \ 'cache_enabled': 1,
            \ }
    endif

    " Most prefer to automatically switch to the current file directory when
    " a new buffer is opened; to prevent this behavior, add the following to
    " your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_autochdir = 1
    " The directory check keeps a jump to a path that no longer exists - a
    " quickfix entry pointing into a cleaned build or scratch area - from
    " aborting with E344 before the buffer is shown.
    if !exists('g:sivim_no_autochdir')
        autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" && isdirectory(expand('%:p:h'))
            \ | silent! lcd %:p:h | endif
        " Always switch to the current file directory
    endif

    "set autowrite                       " Automatically write a file when leaving a modified buffer
    set shortmess+=filmnrxoOtT          " Abbrev. of messages (avoids 'hit enter')
    set viewoptions=folds,options,cursor,unix,slash " Better Unix / Windows compatibility
    set virtualedit=onemore             " Allow for cursor beyond last character
    set nospell                         " Spell checking on for prose only
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

    " Spelling is noise in source, where every signal and type name is a
    " miss. Enable it where the buffer really is prose.
    augroup sivim_spell
        autocmd!
        autocmd FileType gitcommit,markdown,text,asciidoc,rst,mail setlocal spell
    augroup END

    " vim-sensible sets 'autoread', but nothing triggers the check. Inside
    " tmux vim-tmux-focus-events delivers FocusGained, so a file regenerated
    " by a flow step - a filelist, a generated CSR header, a sim output -
    " reloads when the pane comes back.
    augroup sivim_checktime
        autocmd!
        autocmd FocusGained,BufEnter * silent! checktime
    augroup END

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

    " Built-in detection maps *.sv/*.svh to the stock 'systemverilog'
    " filetype; this runs after detection and forces the filetype provided
    " by verilog_systemverilog.vim, which has the richer syntax, indent and
    " instance navigation.
    augroup sivim_verilog_filetype
        autocmd!
        autocmd BufNewFile,BufRead *.v,*.vh,*.vp,*.sv,*.svi,*.svh,*.svp,*.sva
            \ setlocal filetype=verilog_systemverilog
    augroup END
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

    " Easier moving in tabs and windows is handled by vim-tmux-navigator,
    " which maps <C-h/j/k/l> and <C-\>. Inside tmux those cross pane borders;
    " outside it they fall back to plain window switching. The matching half
    " lives in .tmux.conf, which forwards the keys only when the pane is
    " running vim.
    " These conflict with the default digraph mapping of <C-K>. To keep that,
    " add the following to your ~/.sivim/config/init.before.vim file:
    "   let g:sivim_no_easyWindows = 1

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
    cnoremap w!! w !sudo tee % >/dev/null

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

    " Yank/paste ring. Bind only to a <Plug> target the plugin really
    " defined, so a ring that is absent or failed to load falls back to
    " plain p and P instead of leaving them as dead keys. Deferred to
    " VimEnter because plugin files are sourced after this one.
    function! s:MapYankRing() abort
        if !empty(maparg('<Plug>(YankyPutAfter)', 'n'))
            nmap p <Plug>(YankyPutAfter)
            xmap p <Plug>(YankyPutAfter)
            nmap P <Plug>(YankyPutBefore)
            xmap P <Plug>(YankyPutBefore)
            nmap <c-n> <Plug>(YankyCycleForward)
            nmap <c-p> <Plug>(YankyCycleBackward)
        elseif !empty(maparg('<Plug>(miniyank-autoput)', 'n'))
            nmap p <Plug>(miniyank-autoput)
            xmap p <Plug>(miniyank-autoput)
            nmap P <Plug>(miniyank-autoPut)
            xmap P <Plug>(miniyank-autoPut)
        endif
    endfunction

    augroup sivim_yank_ring
        autocmd!
        autocmd VimEnter * call s:MapYankRing()
    augroup END

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
        " ALE looks g:ale_linters up by the buffer's own filetype, so every
        " Verilog filetype needs its own entry. verible-verilog-ls lints a
        " single file without elaborating it, so it does not report
        " unresolved modules, packages or includes that live in other
        " directories. Override with g:sivim_verilog_linters in
        " ~/.sivim/config/init.before.vim.
        "
        " ALE ships ghdl, xvhdl, vcom and hdl_checker for VHDL and would run
        " every one it finds; name the one the project actually uses.
        let s:verilog_linters = get(g:, 'sivim_verilog_linters', ['verible_ls'])
        let g:ale_linters = {
            \   'python': ['flake8', 'pylint'],
            \   'verilog': s:verilog_linters,
            \   'systemverilog': s:verilog_linters,
            \   'verilog_systemverilog': s:verilog_linters,
            \   'vhdl': get(g:, 'sivim_vhdl_linters', ['ghdl']),
            \ }

        " Formatting stays on demand (:ALEFix) rather than on save, so it
        " cannot reformat a shared repository against its own house style.
        let g:ale_fixers = {
            \   'verilog': ['verible_format'],
            \   'systemverilog': ['verible_format'],
            \   'verilog_systemverilog': ['verible_format'],
            \ }

        " lightline-ale: show ALE status in the statusline
        let g:lightline#ale#indicator_checking = "•••"
        let g:lightline#ale#indicator_infos = "ℹ"
        let g:lightline#ale#indicator_warnings = "⚠"
        let g:lightline#ale#indicator_errors = "✗"
        let g:lightline#ale#indicator_ok = "✓"

        " SystemVerilog. Every Verilog linter is registered by ALE under the
        " 'verilog' filetype, so its options live in the g:ale_verilog_*
        " namespace whatever the buffer's filetype is.
        let g:ale_verilog_verible_ls_rules =
            \ '-explicit-parameter-storage-type,line-length=length:150'

        " Build verible.filelist at the repository root from
        " flow/manifests/*.f, which is how verible-verilog-ls resolves
        " symbols defined in other directories. With no argument every
        " manifest is used; otherwise name one, e.g. :VeribleFilelist
        " pqs_flare_config_7
        command! -nargs=* -complete=customlist,sivim#verible#Complete
            \ VeribleFilelist call sivim#verible#Generate(<f-args>)
        let g:ale_verilog_xvlog_options = '-sv'

        " Elaborating linters (verilator, xvlog, iverilog) resolve cross-file
        " references only from the directories given here. List the project's
        " include and library directories in ~/.sivim/config/init.before.vim
        " as g:sivim_verilog_incdirs; entries are expanded, so $VARs and ~
        " may be used.
        let s:verilog_incdirs = map(
            \ copy(get(g:, 'sivim_verilog_incdirs', [])), 'expand(v:val)')
        if !empty(s:verilog_incdirs)
            let g:ale_verilog_verilator_options = join(map(
                \ copy(s:verilog_incdirs), '"-I" . v:val . " -y " . v:val'))
            let g:ale_verilog_iverilog_options = join(map(
                \ copy(s:verilog_incdirs), '"-I" . v:val . " -y" . v:val'))
            let g:ale_verilog_xvlog_options .= ' ' . join(map(
                \ copy(s:verilog_incdirs), '"-i " . v:val'))

            " Jump to a definition in another directory with gf / :find.
            let &path = &path . ',' . join(s:verilog_incdirs, ',')
        endif

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

    " Verilog / SystemVerilog {
        " verilog_systemverilog.vim's syntax folding is opt-in. With no fold
        " list 'foldmethod=syntax' produces no folds at all, leaving <space>
        " and the <leader>f0-f9 level mappings inert in the filetype they are
        " most wanted in.
        let g:verilog_syntax_fold_lst = get(g:, 'sivim_verilog_fold_lst', 'all')

        " Hierarchy navigation. Following an instance needs a tags file built
        " with universal-ctags.
        augroup sivim_verilog_maps
            autocmd!
            autocmd FileType verilog_systemverilog
                \ nnoremap <buffer> <LocalLeader>fi :VerilogFollowInstance<CR>
                \|nnoremap <buffer> <LocalLeader>fp :VerilogFollowPort<CR>
                \|nnoremap <buffer> <LocalLeader>fr :VerilogReturnInstance<CR>
                \|nnoremap <buffer> <LocalLeader>gi :VerilogGotoInstanceStart<CR>
        augroup END

        " Simulation logs into the quickfix list. The compiler plugins
        " shipped with verilog_systemverilog.vim supply each tool's
        " errorformat, and verilog_common.vim appends the UVM report
        " patterns, so :cn / :cp step from UVM_ERROR straight to the line
        " that reported it instead of grepping the log by hand.
        let g:verilog_efm_uvm_lst = get(g:, 'sivim_verilog_efm_uvm_lst', 'all')
        let g:verilog_efm_quickfix_clean = 1

        " :SimLog sim.log         read with g:sivim_simulator (default ncverilog)
        " :SimLog vcs sim.log     name the compiler explicitly
        function! s:SimLog(...) abort
            let l:compiler = get(g:, 'sivim_simulator', 'ncverilog')
            let l:args = copy(a:000)

            " A leading argument that is not a path names the compiler.
            if len(l:args) > 1 && !filereadable(expand(l:args[0]))
                let l:compiler = remove(l:args, 0)
            endif

            let l:log = expand(join(l:args, ' '))

            if !filereadable(l:log)
                echohl WarningMsg
                echomsg 'SimLog: cannot read ' . l:log
                echohl None
                return
            endif

            execute 'compiler!' l:compiler
            execute 'cfile' fnameescape(l:log)
            copen
        endfunction

        command! -nargs=+ -complete=file SimLog call s:SimLog(<f-args>)
    " }

    " Yank/paste ring {
        if s:have_yanky
            lua pcall(function() require('yanky').setup() end)
        endif
    " }

    " Commenting {
        if has('nvim')
            lua pcall(function() require('Comment').setup() end)
        endif
    " }

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

    " Central session store {
    " Session files mirror the project path under a central directory, so
    " nothing is written into the project itself. tmux-resurrect reads the
    " same location via its 'central' strategy, which lives in the dotfiles
    " repository (lib/tmux-resurrect-central.sh) because that is what owns
    " tmux and installs the plugin. Keep the path convention below in step
    " with that script.
    " Run :ObsessionHere once per project to start tracking.
    " Key on the git work tree rather than the cwd. The autochdir autocmd
    " above moves vim's process cwd to the open file's directory, which is
    " also what tmux records for the pane, so neither is stable. The work
    " tree resolves the same from any subdirectory, so this and the
    " tmux-resurrect strategy agree.
    function! s:SessionKey() abort
        let l:dir = getcwd()
        let l:top = system('git -C ' . shellescape(l:dir) . ' rev-parse --show-toplevel 2>/dev/null')
        let l:top = substitute(l:top, '\n', '', 'g')
        return (v:shell_error == 0 && !empty(l:top)) ? l:top : l:dir
    endfunction

    function! s:SessionFile() abort
        let l:root = empty($XDG_DATA_HOME) ? $HOME . '/.local/share' : $XDG_DATA_HOME
        return l:root . '/nvim-sessions' . s:SessionKey() . '/Session.vim'
    endfunction

    function! s:ObsessionHere() abort
        let l:file = s:SessionFile()
        call mkdir(fnamemodify(l:file, ':h'), 'p')
        execute 'Obsession' fnameescape(l:file)
    endfunction

    command! ObsessionHere call s:ObsessionHere()
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
