" quickrun: runner/terminal: Runs by terminal feature.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:is_win = has('win32')
let s:runner = {
\   'config': {
\     'name': 'default',
\     'opener': 'new',
\     'into': 0,
\     'env': {},
\   },
\ }

let s:wins = {}

function s:runner.validate() abort
  if !has('terminal')
    throw 'Needs +terminal feature.'
  endif
  if !s:is_win && !executable('sh')
    throw 'Needs "sh" on other than MS Windows.'
  endif
endfunction

function s:runner.init(session) abort
  let a:session.config.outputter = 'null'
endfunction

function s:runner.run(commands, input, session) abort
  let command = join(a:commands, ' && ')
  if a:input !=# ''
    let inputfile = a:session.tempname()
    call writefile(split(a:input, "\n", 1), inputfile, 'b')
    let command = printf('(%s) < %s', command, inputfile)
  endif
  let cmd_arg = s:is_win ? printf('cmd.exe /c (%s)', command)
  \                      : ['sh', '-c', command]
  let options = {
  \   'term_name': 'quickrun: ' . command,
  \   'curwin': 1,
  \   'close_cb': self._job_close_cb,
  \   'exit_cb': self._job_exit_cb,
  \   'env': self.config.env,
  \ }

  let self._key = a:session.continue()
  let prev_winid = win_getid()

  let jumped = s:goto_last_win(self.config.name)
  if !jumped
    execute self.config.opener
    let s:wins[self.config.name] += [win_getid()]
  endif
  let self._bufnr = term_start(cmd_arg, options)
  setlocal bufhidden=wipe
  if !self.config.into
    call win_gotoid(prev_winid)
  endif
endfunction

function s:runner.sweep() abort
  if has_key(self, '_bufnr') && bufexists(self._bufnr)
    let job = term_getjob(self._bufnr)
    while job_status(job) ==# 'run'
      call job_stop(job)
    endwhile
  endif
endfunction

function s:runner._job_close_cb(channel) abort
  if has_key(self, '_job_exited')
    call quickrun#session#call(self._key, 'finish', self._job_exited)
  else
    let self._job_exited = 0
  endif
endfunction

function s:runner._job_exit_cb(job, exit_status) abort
  if has_key(self, '_job_exited')
    call quickrun#session#call(self._key, 'finish', a:exit_status)
  else
    let self._job_exited = a:exit_status
  endif
endfunction

function s:goto_last_win(name) abort
  if !has_key(s:wins, a:name)
    let s:wins[a:name] = []
  endif

  " sweep
  call filter(s:wins[a:name], 'win_id2tabwin(v:val)[0] != 0')

  for win_id in s:wins[a:name]
    let winnr = win_id2win(win_id)
    if winnr
      call win_gotoid(win_id)
      return 1
    endif
  endfor
  return 0
endfunction

function quickrun#runner#terminal#new() abort
  return deepcopy(s:runner)
endfunction
