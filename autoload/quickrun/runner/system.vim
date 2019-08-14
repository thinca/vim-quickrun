" quickrun: runner/system: Runs by system().
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:runner = {}

function s:runner.run(commands, input, session) abort
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

function s:execute(cmd, input) abort
  let is_cmd_exe = &shell =~? 'cmd\.exe'
  try
    if is_cmd_exe
      let sxq = &shellxquote
      let &shellxquote = '"'
    endif
    let cmd = a:cmd

    if v:version < 704 || (v:version == 704 && !has('patch132'))
      let cmd = g:quickrun#V.Process.iconv(cmd, &encoding, &termencoding)
    endif
    let result = a:input ==# '' ? system(cmd)
    \                           : system(cmd, a:input)
  finally
    if is_cmd_exe
      let &shellxquote = sxq
    endif
  endtry
  return [result, v:shell_error]
endfunction


function quickrun#runner#system#new() abort
  return deepcopy(s:runner)
endfunction
