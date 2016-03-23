let s:save_cpo = &cpo
set cpo&vim

" * queries: [(QueueLabel, QueueBody)]
" * logs: [(String, String, String)] stdin, stdout, stderr
" * vp: vimproc dict
" * buffer_out, buffer_err: String
"     * current buffered vp output/error
" * vars: dict
" * supervisor: (String, String, String) to try of() again
let s:_process_info = {}

function! s:_vital_loaded(V) abort
  let s:L = a:V.import('Data.List')
  let s:S = a:V.import('Data.String')
  let s:P = a:V.import('Process')
endfunction

function! s:_vital_depends() abort
  return ['Data.List', 'Data.String', 'Process']
endfunction

function! s:is_available() abort
  return s:P.has_vimproc()
endfunction

" supervisor strategy
" * Failed to spawn the process: exception
" * The process has been dead: start from scratch silently (see tick() for details)
function! s:of(command, dir, initial_queries) abort
  let label = s:S.hash(printf(
        \ '%s--%s--%s',
        \ type(a:command) == type('') ? a:command : join(a:command, ' '),
        \ a:dir,
        \ join(a:initial_queries, ';')))

  " Reset if the process is dead
  if has_key(s:_process_info, label)
    if get(s:_process_info[label].vp.checkpid(), 0, '') !=# 'run'
      call remove(s:_process_info, label)
    endif
  endif

  if !has_key(s:_process_info, label)
    if len(a:dir)
      let cwd = getcwd()
      execute 'lcd' a:dir
    endif
    try
      let vp = vimproc#popen3(a:command)
    finally
      if exists('cwd')
        execute 'lcd' cwd
      endif
    endtry

    let supervisor = {
          \ 'command': a:command,
          \ 'dir': a:dir,
          \ 'initial_queries': a:initial_queries}
    let s:_process_info[label] = {
          \ 'logs': [], 'queries': a:initial_queries, 'vp': vp,
          \ 'buffer_out': '', 'buffer_err': '', 'vars': {},
          \ 'supervisor': supervisor}
  endif

  call s:tick(label)
  return label
endfunction

function! s:_split_at_last_newline(str) abort
  if len(a:str) == 0
    return ['', '']
  endif

  let xs = split(a:str, ".*\n\\zs", 1)
  if len(xs) >= 2
    return [xs[0], xs[1]]
  else
    return ['', a:str]
  endif
endfunction

function! s:_read(pi, rname) abort
  let pi = a:pi

  let [out, err] = [pi.vp.stdout.read(-1, 0), pi.vp.stderr.read(-1, 0)]
  call add(pi.logs, ['', out, err])

  " stdout: store into vars and buffer_out
  if !has_key(pi.vars, a:rname)
    let pi.vars[a:rname] = ['', '']
  endif
  let [left, right] = s:_split_at_last_newline(pi.buffer_out . out)
  if a:rname !=# '_'
    let pi.vars[a:rname][0] .= left
  endif
  let pi.buffer_out = right

  " stderr: directly store into buffer_err
  let pi.buffer_err .= err
endfunction

function! s:tick(label) abort
  let pi = s:_process_info[a:label]

  if len(pi.queries) == 0
    return
  endif

  let is_alive = get(pi.vp.checkpid(), 0, '') ==# 'run'

  if !is_alive
    " Use the default supervisor.
    " Default supervisor: restart the process with fresh state.
    " (Accumulated queue won't be kept)
    call s:of(pi.supervisor.command, pi.supervisor.dir, pi.supervisor.initial_queries)
    return
  endif

  let qlabel = pi.queries[0][0]

  if qlabel ==# '*read*'
    let rname = pi.queries[0][1]
    let rtil = pi.queries[0][2]

    call s:_read(pi, rname)

    let pattern = "\\(^\\|\n\\)" . rtil . '$'
    " when wait ended:
    if pi.buffer_out =~ pattern
      if rname !=# '_'
        let pi.vars[rname][0] .= s:S.substitute_last(pi.buffer_out, pattern, '')
        let pi.vars[rname][1] = pi.buffer_err
      endif

      call remove(pi.queries, 0)
      let pi.buffer_out = ''
      let pi.buffer_err = ''

      call s:tick(a:label)
    endif
  elseif qlabel ==# '*read-all*'
    let rname = pi.queries[0][1]
    call pi.vp.stdin.close()
    call s:_read(pi, rname)

    " when wait ended:
    if get(s:_process_info[a:label].vp.checkpid(), 0, '') !=# 'run'
      if rname !=# '_'
        let pi.vars[rname][0] .= pi.buffer_out
        let pi.vars[rname][1] = pi.buffer_err
      endif

      call remove(pi.queries, 0)
      let pi.buffer_out = ''
      let pi.buffer_err = ''
    endif

  elseif qlabel ==# '*writeln*'
    let wbody = pi.queries[0][1]
    call pi.vp.stdin.write(wbody . "\n")
    call remove(pi.queries, 0)

    call add(pi.logs, [wbody . "\n", '', ''])

    call s:tick(a:label)
  else
    " must not happen
    throw 'ConcurrentProcess: must not happen'
  endif
endfunction

" returns [out, err, timedout_p]
function! s:consume_all_blocking(label, varname, timeout_sec) abort
  let start = reltime()
  while 1
    call s:tick(a:label)
    if s:is_done(a:label, a:varname)
      return s:consume(a:label, a:varname) + [0] " 0 as 'Did not timed out'
    elseif reltime(start)[0] >= a:timeout_sec
      return s:consume(a:label, a:varname) + [1] " 1 as 'Unfortunately it timed out'
    endif
  endwhile
endfunction

function! s:consume(label, varname) abort
  call s:tick(a:label)
  let pi = s:_process_info[a:label]

  if has_key(pi.vars, a:varname)
    let memo = pi.vars[a:varname]
    call remove(pi.vars, a:varname)
    return memo
  else
    return ['', '']
  endif
endfunction

function! s:is_done(label, rname) abort
  let reads = filter(
        \ copy(s:_process_info[a:label].queries),
        \ "v:val[0] ==# '*read*' || v:val[0] ==# '*read-all*'")
  return s:L.all(
        \ printf('v:val[1] !=# %s', string(a:rname)),
        \ reads)
endfunction

function! s:queue(label, queries) abort
  call s:tick(a:label)
  let s:_process_info[a:label].queries += a:queries
endfunction

function! s:is_busy(label) abort
  call s:tick(a:label)

  return len(s:_process_info[a:label].queries) > 0
endfunction

function! s:shutdown(label) abort
  let pi = s:_process_info[a:label]
  call pi.vp.kill(g:vimproc#SIGKILL)
  call pi.vp.checkpid()
  unlet s:_process_info[a:label]
endfunction

" Just to wipe out the log
function! s:log_clear(label) abort
  let s:_process_info[a:label].logs = []
endfunction

" Print out log, and wipe out the log
function! s:log_dump(label) abort
  echo '-----------------------------'
  for [stdin, stdout, stderr] in s:_process_info[a:label].logs
    echon stdin
    echon stdout
    if stderr !=# ''
      echon printf('!!!%s!!!', stderr)
    endif
  endfor
  let s:_process_info[a:label].logs = []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0:
