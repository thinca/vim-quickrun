" quickrun: runner: system
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {}

function! s:runner.run(commands, input, session)
  let code = 0
  for cmd in a:commands
    let [result, code] = s:execute(cmd, a:input)
    call a:session.output(result)
    if code != 0
      break
    endif
  endfor
  return code
endfunction

function! s:execute(cmd, input)
  if a:cmd =~# '^\s*:'
    " A vim command.
    try
      let result = quickrun#execute(a:cmd)
    catch
      return ['', 1]
    endtry
    return [result, 0]
  endif

  let is_cmd_exe = &shell =~? 'cmd\.exe'
  try
    if is_cmd_exe
      let sxq = &shellxquote
      let &shellxquote = '"'
    endif
    let cmd = a:cmd

    let cmd = g:quickrun#V.iconv(cmd, &encoding, &termencoding)
    let result = a:input ==# '' ? system(cmd)
    \                           : system(cmd, a:input)
  finally
    if is_cmd_exe
      let &shellxquote = sxq
    endif
  endtry
  return [result, v:shell_error]
endfunction


function! quickrun#runner#system#new()
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
