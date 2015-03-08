" quickrun: runner/vimscript: Runs commands as vim commands.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {}

function! s:runner.run(commands, input, session) abort
  let code = 0
  for cmd in a:commands
    let [result, code] = s:execute(cmd)
    call a:session.output(result)
    if code != 0
      break
    endif
  endfor
  return code
endfunction

function! s:execute(cmd) abort
  let result = ''
  let error = 0
  let temp = tempname()

  let save_vfile = &verbosefile
  let &verbosefile = temp

  try
    silent execute a:cmd
  catch
    let error = 1
    silent echo v:throwpoint
    silent echo matchstr(v:exception, '^Vim\%((\w*)\)\?:\s*\zs.*')
  finally
    if &verbosefile ==# temp
      let &verbosefile = save_vfile
    endif
  endtry

  if filereadable(temp)
    let result .= join(readfile(temp, 'b'), "\n")
    call delete(temp)
  endif

  return [result, error]
endfunction


function! quickrun#runner#vimscript#new() abort
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
