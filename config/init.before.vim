let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 0
if !has('gui_running')
    set guicursor=
endif

"let g:syntastic_c_config_file="~/.sivim/config/syntastic_c"
"let g:syntastic_cpp_config_file="~/.sivim/config/syntastic_c"
"let g:syntastic_cpp_check_header=1
"let g:syntastic_cpp_compiler='clang++'
"let g:syntastic_cpp_compiler_options='-std=c++11 -stdlib=libstdc++'
let g:syntastic_c_checkers = []
let g:syntastic_cpp_checkers = []

"let g:miniyank_filename = "/tmp/".$USER."_miniyank.mpack"
if executable('python3')
    let g:python3_host_prog = exepath('python3')
endif

" Linters. verible_ls checks a single file without elaborating it; the
" elaborating linters resolve cross-file references only through
" g:sivim_verilog_incdirs below.
"let g:sivim_verilog_linters = ['verible_ls']
"let g:sivim_vhdl_linters = ['ghdl']

" Include and library directories for the elaborating linters, and for
" gf / :find. Entries are expanded, so $VARs and ~ may be used.
"let g:sivim_verilog_incdirs = [
"    \ '$PROJECT_ROOT/rtl/include',
"    \ '$PROJECT_ROOT/tb/include',
"    \ ]

" Simulator used by :SimLog to pick the quickfix errorformat. Any compiler
" plugin shipped with verilog_systemverilog.vim: ncverilog, vcs, msim,
" verilator, iverilog, spyglass, leda, cver.
"let g:sivim_simulator = 'ncverilog'

" UVM severities collected into the quickfix list: 'all', or a
" comma-separated subset of info, warning, error, fatal.
"let g:sivim_verilog_efm_uvm_lst = 'error,fatal'

" Syntax fold groups for SystemVerilog; see :help verilog_syntax_fold_lst.
"let g:sivim_verilog_fold_lst = 'all'
