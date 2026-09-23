" Generate a verible.filelist from the repository's flow/manifests/*.f so
" verible-verilog-ls can resolve symbols across directories.

let s:manifest_glob = 'flow/manifests/*.f'

function! s:Root(...) abort
    let l:start = a:0 ? a:1 : expand('%:p:h')

    if empty(l:start)
        let l:start = getcwd()
    endif

    let l:git = finddir('.git', l:start . ';')

    if empty(l:git)
        let l:git = findfile('.git', l:start . ';')
    endif

    return empty(l:git) ? '' : fnamemodify(l:git, ':p:h:h')
endfunction

" Substitute $VAR and ${VAR} from the environment. A variable that is unset
" falls back to the repository root when that yields an existing path.
" Returns an empty string when the path cannot be resolved.
function! s:Expand(str, root) abort
    let l:out = a:str

    for l:i in range(16)
        let l:var = matchlist(l:out, '\$\({\)\=\([A-Za-z_][A-Za-z0-9_]*\)}\=')

        if empty(l:var)
            return l:out
        endif

        let l:pat = '\V' . escape(l:var[0], '\')
        let l:val = exists('*getenv') ? getenv(l:var[2]) : eval('$' . l:var[2])

        if type(l:val) is v:t_string && !empty(l:val)
            let l:out = substitute(l:out, l:pat, escape(l:val, '\&~'), 'g')
            continue
        endif

        let l:try = substitute(l:out, l:pat, escape(a:root, '\&~'), 'g')

        if filereadable(l:try) || isdirectory(l:try)
            let l:out = l:try
            continue
        endif

        return ''
    endfor

    return ''
endfunction

function! s:Parse(manifest, root, state) abort
    let l:key = resolve(fnamemodify(a:manifest, ':p'))

    if has_key(a:state.seen, l:key) || !filereadable(l:key)
        return
    endif

    let a:state.seen[l:key] = 1

    for l:raw in readfile(l:key)
        let l:line = substitute(substitute(l:raw, '#.*', '', ''), '^\s*\|\s*$', '', 'g')

        if empty(l:line)
            continue
        endif

        if l:line =~# '^-[fF]\s'
            let l:nested = s:Expand(substitute(l:line, '^-[fF]\s*', '', ''), a:root)

            if empty(l:nested)
                let a:state.unresolved += 1
            else
                call s:Parse(l:nested, a:root, a:state)
            endif
        elseif l:line =~# '^+incdir+'
            for l:dir in split(substitute(l:line, '^+incdir+', '', ''), '+')
                let l:path = s:Expand(l:dir, a:root)

                if empty(l:path)
                    let a:state.unresolved += 1
                elseif !has_key(a:state.incdirs, l:path)
                    let a:state.incdirs[l:path] = 1
                endif
            endfor
        elseif l:line =~# '^[-+]'
            let a:state.ignored += 1
        else
            let l:path = s:Expand(l:line, a:root)

            if empty(l:path)
                let a:state.unresolved += 1
            elseif !has_key(a:state.files, l:path)
                let a:state.files[l:path] = 1
                call add(a:state.order, l:path)
            endif
        endif
    endfor
endfunction

" Paths inside the repository are written relative to it so the filelist
" survives a move; anything outside stays absolute.
function! s:Relative(path, root) abort
    let l:prefix = a:root . '/'

    return stridx(a:path, l:prefix) == 0 ? a:path[len(l:prefix):] : a:path
endfunction

function! sivim#verible#Complete(lead, ...) abort
    let l:root = s:Root()

    if empty(l:root)
        return []
    endif

    let l:names = map(glob(l:root . '/' . s:manifest_glob, 0, 1), 'fnamemodify(v:val, ":t:r")')

    return filter(l:names, 'stridx(v:val, a:lead) == 0')
endfunction

function! sivim#verible#Generate(...) abort
    let l:root = s:Root()

    if empty(l:root)
        return s:Warn('not inside a git repository')
    endif

    let l:manifests = []

    if a:0
        for l:arg in a:000
            let l:hit = filereadable(l:arg)
                \ ? l:arg
                \ : l:root . '/flow/manifests/' . fnamemodify(l:arg, ':r') . '.f'

            if filereadable(l:hit)
                call add(l:manifests, l:hit)
            else
                return s:Warn('no such manifest: ' . l:arg)
            endif
        endfor
    else
        let l:manifests = glob(l:root . '/' . s:manifest_glob, 0, 1)
    endif

    if empty(l:manifests)
        return s:Warn('no manifests found under ' . l:root . '/flow/manifests')
    endif

    let l:state = {
        \   'seen': {}, 'files': {}, 'incdirs': {}, 'order': [],
        \   'unresolved': 0, 'ignored': 0,
        \ }

    for l:manifest in l:manifests
        call s:Parse(l:manifest, l:root, l:state)
    endfor

    if empty(l:state.order)
        return s:Warn('no source files resolved; source flow/project/conf.sh first')
    endif

    " Every directory holding a header is an include directory, so that
    " `include of a file in another directory resolves.
    for l:path in l:state.order
        if l:path =~? '\.\(svh\|svi\|vh\)$'
            let l:state.incdirs[fnamemodify(l:path, ':h')] = 1
        endif
    endfor

    let l:lines = ['# Generated by :VeribleFilelist. Do not edit.']

    for l:dir in sort(keys(l:state.incdirs))
        call add(l:lines, '+incdir+' . s:Relative(l:dir, l:root))
    endfor

    for l:path in l:state.order
        call add(l:lines, s:Relative(l:path, l:root))
    endfor

    let l:target = l:root . '/verible.filelist'

    if writefile(l:lines, l:target) != 0
        return s:Warn('could not write ' . l:target)
    endif

    let l:msg = printf('verible.filelist: %d files, %d include dirs, from %d manifest(s)',
        \ len(l:state.order), len(l:state.incdirs), len(l:manifests))

    if l:state.unresolved
        let l:msg .= printf(' (%d path(s) unresolved - source flow/project/conf.sh)', l:state.unresolved)
        call s:Warn(l:msg)
    else
        echomsg l:msg
    endif

    " verible-verilog-ls reads the filelist once at startup.
    silent! ALEStopAllLSPs
    silent! ALELint
endfunction

function! s:Warn(msg) abort
    echohl WarningMsg
    echomsg 'VeribleFilelist: ' . a:msg
    echohl None
endfunction
