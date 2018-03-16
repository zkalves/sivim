" Modeline  {
" vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker={,} foldlevel=0 foldmethod=marker spell:
"
" }

" Use before config if available {
    if filereadable(expand("~/.sivim/config/init.before.vim"))
        source ~/.sivim/config/init.before.vim
    endif
" }

"" Plugin manager {
    " Plugins will be downloaded under the specified directory.
    set runtimepath+=~/.sivim/plugins/repos/github.com/Shougo/dein.vim
    if dein#load_state('~/.sivim/plugins')
        call dein#begin('~/.sivim/plugins')
        call dein#add('Shougo/dein.vim')
        " Declare the list of plugins.
        call dein#add('morhetz/gruvbox')                     " Default colorscheme
        call dein#add('godlygeek/tabular')                   " Text alignment
        call dein#add('nathanaelkane/vim-indent-guides')     " Visually display indent levels
        "call dein#add('python-mode/python-mode')            " Convert neovim in a Python IDE
        call dein#add('scrooloose/nerdcommenter')            " Comment functions
        call dein#add('tmhedberg/SimpylFold')                " Code folding for python
        call dein#add('tpope/vim-fugitive')                  " Git wrapper
        call dein#add('tpope/vim-sensible')                  " Basic configs
        call dein#add('vim-airline/vim-airline')             " status line
        call dein#add('vim-airline/vim-airline-themes')      " Themes for airline
        call dein#add('vim-syntastic/syntastic')             " Syntax checker
        call dein#add('easymotion/vim-easymotion')           " Move easier through the code
        " Unite dependencies:
        call dein#add('Shougo/vimproc.vim', {'build': 'make'})
        call dein#add('Shougo/unite.vim')
        call dein#add('Shougo/neomru.vim')
        call dein#add('Shougo/unite-outline')
        call dein#add('tsukkee/unite-tag')
        " List ends here. Plugins become visible to Vim after this call.
        call dein#end()
        call dein#save_state()
    endif

    " Install missing plugins
    if dein#check_install()
        call dein#install()
    endif
"" }

" General {
    " Allow to trigger background
    function! ToggleBG()
        let s:tbg = &background
        " Inversion
        if s:tbg == "dark"
            set background=light
        else
            set background=dark
        endif
    endfunction

    function! SwitchCTRST()
        let s:tbg = &background
        if s:tbg == "dark"
            let s:sctrst = g:gruvbox_contrast_dark
        else
            let s:sctrst = g:gruvbox_contrast_light
        endif

        if s:sctrst == "medium"
            let s:sctrst = 'soft'
        elseif s:sctrst == "soft"
            let s:sctrst = 'hard'
        else
            let s:sctrst = 'medium'
        endif

        if s:tbg == "dark"
            let g:gruvbox_contrast_dark = s:sctrst
        else
            let g:gruvbox_contrast_light = s:sctrst
        endif
        colorscheme gruvbox
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

" Vim UI {

    " Set colorscheme {
        set background=dark
        let g:gruvbox_contrast_dark = 'medium'
        colorscheme gruvbox
    " }

    set showmode                    " Display the current mode

    set cursorline                  " Highlight current line

    highlight clear SignColumn      " SignColumn should match background
    highlight clear LineNr          " Current line number row will have same background color in relative mode
    "highlight clear CursorLineNr    " Remove highlight color from current line number

    set linespace=0                 " No extra spaces between rows
    set number                      " Line numbers on
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
    set foldmethod=indent           " Enable folding
    set foldlevel=99
    set list
" }

" Formatting {

    set nowrap                      " Do not wrap long lines
    set shiftwidth=4                " Use indents of 4 spaces
    set expandtab                   " Tabs are spaces, not tabs
    set tabstop=4                   " An indentation every four columns
    set softtabstop=4               " Let backspace delete indent
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
    autocmd BufNewFile,BufRead *.html.twig set filetype=html.twig
    autocmd FileType haskell,puppet,ruby,yml setlocal expandtab shiftwidth=2 softtabstop=2
    " preceding line best in a plugin but here for now.

    autocmd BufNewFile,BufRead *.coffee set filetype=coffee

    " Workaround vim-commentary for Haskell
    autocmd FileType haskell setlocal commentstring=--\ %s
    " Workaround broken colour highlighting in Haskell
    autocmd FileType haskell,rust setlocal nospell

    " Flag unnecessary whitespace
    highlight BadWhitespace ctermbg=red guibg=darkred
    autocmd BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
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

    " Update plugins on startup
    noremap <leader>du :call dein#update()<CR>

    " Change background color
    noremap <leader>bg :call ToggleBG()<CR>
    noremap <leader>bc :call SwitchCTRST()<CR>

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
        nnoremap <C-J> <C-W><C-J>
        nnoremap <C-K> <C-W><C-K>
        nnoremap <C-L> <C-W><C-L>
        nnoremap <C-H> <C-W><C-H>
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
    " Change Working Directory to that of the current file
    cmap cwd lcd %:p:h
    cmap cd. lcd %:p:h

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
    nmap <leader>rt :set tabstop=8 <bar> :retab <bar> :set tabstop=3 <cr>

    " Disable F1 help
    nmap <F1> <nop>
" }

" Plugin configuration {
    " Tabularize {
        if isdirectory(expand("~/.sivim/plugins/repos/github.com/godlygeek/tabular"))
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
        endif
    " }

    " PyMode {
        " Disable if python support not present
        if !has('python') && !has('python3')
            let g:pymode = 0
        endif

        if isdirectory(expand("~/.sivim/plugins/repos/github.com/python-mode"))
            let g:pymode_lint_checkers = ['pyflakes']
            let g:pymode_trim_whitespaces = 0
            let g:pymode_options = 0
            let g:pymode_rope = 0
        endif
    " }

    " Fugitive {
        if isdirectory(expand("~/.sivim/plugins/repos/github.com/vim-fugitive"))
            nnoremap <silent> <leader>gs :Gstatus<CR>
            nnoremap <silent> <leader>gd :Gdiff<CR>
            nnoremap <silent> <leader>gc :Gcommit<CR>
            nnoremap <silent> <leader>gb :Gblame<CR>
            nnoremap <silent> <leader>gl :Glog<CR>
            nnoremap <silent> <leader>gp :Git push<CR>
            nnoremap <silent> <leader>gr :Gread<CR>
            nnoremap <silent> <leader>gw :Gwrite<CR>
            nnoremap <silent> <leader>ge :Gedit<CR>
            " Mnemonic _i_nteractive
            nnoremap <silent> <leader>gi :Git add -p %<CR>
            nnoremap <silent> <leader>gg :SignifyToggle<CR>
        endif
    "}

    " indent_guides {
        if isdirectory(expand("~/.sivim/plugins/repos/github.com/nathanaelkane/vim-indent-guides/"))
            let g:indent_guides_start_level = 2
            let g:indent_guides_guide_size = 1
            let g:indent_guides_enable_on_vim_startup = 1
        endif
    " }

    " vim-airline {
        " Set configuration options for the statusline plugin vim-airline.
        " Use the powerline theme and optionally enable powerline symbols.
        " Uses the symbols , , , , , , and .in the statusline.
        " If the previous symbols do not render for you then install a
        " powerline enabled font.

        " See `:echo g:airline_theme_map` for some more choices
        " Default in terminal vim is 'dark'
        if isdirectory(expand("~/.sivim/plugins/repos/github.com/vim-airline/vim-airline-themes/"))
            let g:airline_powerline_fonts = 1
            if !exists('g:airline_theme')
                let g:airline_theme = 'dark'
            endif
            if !exists('g:airline_symbols')
                let g:airline_symbols = {}
            endif

            " unicode symbols
            let g:airline_left_sep = '»'
            let g:airline_left_sep = '▶'
            let g:airline_right_sep = '«'
            let g:airline_right_sep = '◀'
            let g:airline_symbols.linenr = '␊'
            let g:airline_symbols.linenr = '␤'
            let g:airline_symbols.linenr = '¶'
            let g:airline_symbols.branch = '⎇'
            let g:airline_symbols.paste = 'ρ'
            let g:airline_symbols.paste = 'Þ'
            let g:airline_symbols.paste = '∥'
            let g:airline_symbols.whitespace = 'Ξ'

            " airline symbols
            let g:airline_left_sep = ''
            let g:airline_left_alt_sep = ''
            let g:airline_right_sep = ''
            let g:airline_right_alt_sep = ''
            let g:airline_symbols.branch = ''
            let g:airline_symbols.readonly = ''
            let g:airline_symbols.linenr = ''
            "" Use the default set of separators with a few customizations
            "let g:airline_left_sep='›'  " Slightly fancier than '>'
            "let g:airline_right_sep='‹' " Slightly fancier than '<'
        endif
    " }

    " vim-syntastic {
        set statusline+=%#warningmsg#
        set statusline+=%{SyntasticStatuslineFlag()}
        set statusline+=%*

        let g:syntastic_always_populate_loc_list = 1
        let g:syntastic_auto_loc_list = 1
        let g:syntastic_check_on_open = 1
        let g:syntastic_check_on_wq = 0
    " }

    " Unite {
        let g:unite_source_codesearch_ignore_case = 1
        let g:unite_enable_start_insert = 0
        let g:unite_enable_short_source_mes = 0
        let g:unite_force_overwrite_statusline = 0
        let g:unite_prompt = '>>> '
        let g:unite_marked_icon = '✓'
        let g:unite_candidate_icon = '∘'
        let g:unite_winheight = 15
        let g:unite_update_time = 200
        let g:unite_split_rule = 'botright'
        let g:unite_source_buffer_time_format = '(%d-%m-%Y %H:%M:%S) '
        let g:unite_source_file_mru_time_format = '(%d-%m-%Y %H:%M:%S) '
        let g:unite_source_directory_mru_time_format = '(%d-%m-%Y %H:%M:%S) '
        let g:unite_data_directory='~/.sivim/cache/unite'
        let g:unite_source_history_yank_enable=1
        if executable('ag')
            let g:unite_source_grep_command = 'ag'
            let g:unite_source_grep_default_opts='-i -r --line-numbers --nocolor --nogroup -S'
            let g:unite_source_grep_recursive_opt = ''
        endif

        " files
        nnoremap <silent><Leader>uo :Unite -silent -start-insert file<CR>
        nnoremap <silent><Leader>uO :Unite -silent -start-insert file_rec/async<CR>
        nnoremap <silent><Leader>um :Unite -silent file_mru<CR>
        " buffers
        nnoremap <silent><Leader>ub :Unite -silent buffer<CR>
        " tabs
        nnoremap <silent><Leader>uB :Unite -silent tab<CR>
        " grep
        nnoremap <silent><Leader>ua :Unite -silent -no-quit grep<CR>
        " tasks
        nnoremap <silent><Leader>u; :Unite -silent -toggle
                    \ grep:%::FIXME\|TODO\|NOTE\|XXX\|COMBAK\|@todo<CR>

        " menus
        let g:unite_source_menu_menus = {}

    " }
"}

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
