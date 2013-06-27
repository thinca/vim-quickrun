let s:save_cpo = &cpo
set cpo&vim

let s:_auto_label = -1
let s:_processes = {}

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:S = s:V.import('Data.String')
endfunction

function! s:_vital_depends()
  return ['Data.String']
endfunction

function! s:is_available()
  return s:V.has_vimproc()
endfunction

function! s:touch(name, cmd)
  if has_key(s:_processes, a:name)
    return 'existing'
  else
    let p = vimproc#popen3(a:cmd)
    let s:_processes[a:name] = p
    return 'new'
  endif
endfunction

function! s:new(cmd)
  let p = vimproc#popen3(a:cmd)
  let s:_auto_label += 1
  let s:_processes[s:_auto_label] = p
  return s:_auto_label
endfunction

function! s:stop(i)
  let p = s:_processes[a:i]
  call p.kill(9)
  " call p.waitpid()
  unlet s:_processes[a:i]
endfunction

function! s:read(i, endpatterns)
  return s:read_wait(a:i, 0.05, a:endpatterns)
endfunction

function! s:read_wait(i, wait, endpatterns)
  if !has_key(s:_processes, a:i)
    throw printf("ProcessManager doesn't know about %s", a:i)
  endif
  if s:status(a:i) ==# 'inactive'
    return ['', '', 'inactive']
  endif

  let p = s:_processes[a:i]
  let out_memo = ''
  let err_memo = ''
  let lastchanged = reltime()
  while 1
    let [x, y] = [p.stdout.read(), p.stderr.read()]
    if x ==# '' && y ==# ''
      if str2float(reltimestr(reltime(lastchanged))) > a:wait
        return [out_memo, err_memo, 'timedout']
      endif
    else
      let lastchanged = reltime()
      let out_memo .= x
      let err_memo .= y
      for pattern in a:endpatterns
        if out_memo =~ ("\\(^\\|\n\\)" . pattern)
          return [s:S.substitute_last(out_memo, pattern, ''), err_memo, 'matched']
        endif
      endfor
    endif
  endwhile
endfunction

function! s:write(i, str)
  if !has_key(s:_processes, a:i)
    throw printf("ProcessManager doesn't know about %s", a:i)
  endif
  if s:status(a:i) ==# 'inactive'
    return 'inactive'
  endif

  let p = s:_processes[a:i]
  call p.stdin.write(a:str)

  return 'active'
endfunction

function! s:writeln(i, str)
  return s:write(a:i, a:str . "\n")
endfunction

function! s:status(i)
  if !has_key(s:_processes, a:i)
    throw printf("ProcessManager doesn't know about %s", a:i)
  endif
  let p = s:_processes[a:i]
  " vimproc.kill isn't to stop but to ask for the current state.
  " return p.kill(0) ? 'inactive' : 'active'
  " ... checkpid() checks if the process is running AND does waitpid() in C, 
  " so it solves zombie processes.
  return get(p.checkpid(), 0, '') ==# 'run' ?
        \ 'active' : 'inactive'
endfunction

function! s:debug_processes()
  return s:_processes
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
