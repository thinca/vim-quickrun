" quickrun: runner/job: Runs by job feature.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:is_win = g:quickrun#V.Prelude.is_windows()
let s:runner = {
\   'config': {
\     'interval': 0,
\   }
\ }

function! s:runner.validate() abort
  if !has('job')
    throw 'Needs +job feature.'
  endif
  if !exists('*ch_close_in')
    throw 'Needs ch_close_in() builtin function'
  endif
  if !s:is_win && !executable('sh')
    throw 'Needs "sh" on other than MS Windows.'
  endif
endfunction

function! s:runner.run(commands, input, session) abort
  let command = join(a:commands, ' && ')
  let cmd_arg = s:is_win ? printf('cmd.exe /c (%s)', command)
  \                      : ['sh', '-c', command]
  let options = {
  \   'mode': 'raw',
  \   'callback': self._job_cb,
  \   'close_cb': self._job_close_cb,
  \   'exit_cb': self._job_exit_cb,
  \ }
  if a:input ==# ''
    let options.in_io = 'null'
  endif

  if self.config.interval
    let self._timer =
    \   timer_start(self.config.interval, self._timer_cb, {'repeat': -1})
  endif

  let self._key = a:session.continue()
  let self._job = job_start(cmd_arg, options)
  if a:input !=# ''
    let job_ch = job_getchannel(self._job)
    call ch_sendraw(job_ch, a:input)
    call ch_close_in(job_ch)
  endif
endfunction

function! s:runner.sweep() abort
  if has_key(self, '_job')
    while job_status(self._job) ==# 'run'
      call job_stop(self._job)
    endwhile
  endif
  if has_key(self, '_timer')
    call timer_stop(self._timer)
  endif
endfunction

function! s:runner._job_cb(channel, message) abort
  call quickrun#session(self._key, 'output', a:message)
endfunction

function! s:runner._job_close_cb(channel) abort
  if has_key(self, '_job_exited')
    call quickrun#session(self._key, 'finish', self._job_exited)
  else
    let self._job_exited = 0
  endif
endfunction

function! s:runner._job_exit_cb(job, exit_status) abort
  if has_key(self, '_job_exited')
    call quickrun#session(self._key, 'finish', a:exit_status)
  else
    let self._job_exited = a:exit_status
  endif
endfunction

function! s:runner._timer_cb(timer) abort
  if has_key(self, '_job')
    call job_status(self._job)
  endif
endfunction

function! quickrun#runner#job#new() abort
  return deepcopy(s:runner)
endfunction
