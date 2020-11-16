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
