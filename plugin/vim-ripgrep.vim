if exists('g:loaded_rg') || &cp
  finish
endif

let g:loaded_rg = 1

if !exists('g:rg_binary')
  let g:rg_binary = 'rg'
endif

if !exists('g:rg_format')
  let g:rg_format = "%f:%l:%c:%m"
endif

if !exists('g:rg_command')
  let g:rg_command = g:rg_binary . ' --vimgrep'
endif

if !exists('g:rg_root_types')
  let g:rg_root_types = ['.git']
endif

if !exists('g:rg_window_location')
  let g:rg_window_location = 'botright'
endif

if !exists('g:rg_highlight_type')
  let g:rg_highlight_type = 'keyword'
endif

fun! g:RgVisual() range
  call s:RgGrepContext(function('s:RgSearch'), '"' . s:RgGetVisualSelection() . '"')
endfun

fun! s:Rg(txt)
  call s:RgGrepContext(function('s:RgSearch'), s:RgSearchTerm(a:txt))
endfun

fun! s:RgGetVisualSelection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfun

fun! s:RgSearchTerm(txt)
  if empty(a:txt)
    return expand("<cword>")
  else
    return a:txt
  endif
endfun

fun! s:RgSearch(txt)
  let l:rgopts = ' '
  if &ignorecase == 1
    let l:rgopts = l:rgopts . '-i '
  endif
  if &smartcase == 1
    let l:rgopts = l:rgopts . '-S '
  endif
  silent! exe 'grep! ' . l:rgopts . a:txt
  if len(getqflist())
    exe g:rg_window_location 'copen'
    redraw!
    if exists('g:rg_highlight')
      call s:RgHighlight(a:txt)
    endif
  else
    cclose
    redraw!
    echo "No match found for " . a:txt
  endif
endfun

fun! s:RgGrepContext(search, txt)
  let l:grepprgb = &grepprg
  let l:grepformatb = &grepformat
  let &grepprg = g:rg_command
  let &grepformat = g:rg_format
  let l:te = &t_te
  let l:ti = &t_ti
  let l:shellpipe_bak=&shellpipe
  set t_te=
  set t_ti=
  if !has("win32")
    let &shellpipe="&>"
  endif

  call s:RgPathContext(a:search, a:txt)

  let &shellpipe=l:shellpipe_bak
  let &t_te=l:te
  let &t_ti=l:ti
  let &grepprg = l:grepprgb
  let &grepformat = l:grepformatb
endfun

fun! s:RgPathContext(search, txt)
  let l:cwdb = expand('%:p:h')
  exe 'lcd '.g:RgRootDir()
  call a:search(a:txt)
  exe 'lcd '.l:cwdb
endfun

fun! s:RgHighlight(txt)
  call matchadd(g:rg_highlight_type, a:txt)
endfun

fun! g:RgRootDir()
  let l:bwd = expand('%:p:h')
  let l:bufroot = system('cd '. l:bwd . ' && git rev-parse --show-toplevel')
  let l:bufroot = substitute(l:bufroot, '\n', '', 'g')
  return l:bufroot
endfun

fun! s:RgMakePath(dirs, dir)
  return '/'.join(a:dirs[0:index(a:dirs, a:dir)], '/')
endfun

fun! s:RgHasFile(path)
  return filereadable(a:path) || isdirectory(a:path)
endfun

fun! g:RgShowRoot()
  echo g:RgRootDir()
endfun

command! -nargs=* -complete=file Rg :call s:Rg(<q-args>)
command! -complete=file RgRoot :call g:RgShowRoot()
