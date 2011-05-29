" quickrun: runner: system
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {}

function! s:runner.run(commands, input, session)
  for cmd in a:commands
    call a:session.output(s:execute(cmd, a:input))
    if v:shell_error != 0
      break
    endif
  endfor
endfunction

function! s:is_cmd_exe()
  return &shell =~? 'cmd\.exe'
endfunction

function! s:execute(cmd, input)
  if a:cmd =~# '^\s*:'
    " A vim command.
    return quickrun#execute(a:cmd)
  endif

  try
    if s:is_cmd_exe()
      let sxq = &shellxquote
      let &shellxquote = '"'
    endif
    let cmd = a:cmd

    let cmd = iconv(cmd, &encoding, &termencoding)
    return a:input ==# '' ? system(cmd)
    \                    : system(cmd, a:input)
  finally
    if s:is_cmd_exe()
      let &shellxquote = sxq
    endif
  endtry
endfunction


function! quickrun#runner#system#new()
  return copy(s:runner)
endfunction

let &cpo = s:save_cpo
