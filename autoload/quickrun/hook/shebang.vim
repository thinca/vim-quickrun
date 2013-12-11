" quickrun: hook/shebang: Detects shebang.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {}

function! s:hook.on_module_loaded(session, context)
  let line = get(readfile(a:session.config.srcfile, 0, 1), 0, '')
  if line =~# '^#!'
    let a:session.config.command = line[2 :]
    call map(a:session.config.exec, 's:replace_cmd(v:val)')
  endif
endfunction

function! s:replace_cmd(cmd)
  return substitute(a:cmd, '%\@<!%c', '%C', 'g')
endfunction

function! quickrun#hook#shebang#new()
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
