" quickrun: runner/job: Runs by job feature.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:is_win = g:quickrun#V.Prelude.is_windows()
let s:runner = {
\ }

function! s:runner.validate() abort
  if !has('nvim')
    throw 'Available only for neovim'
  endif
endfunction

function! s:runner.run(commands, input, session) abort
  let command = join(a:commands, ' && ')
  let cmd_arg = s:is_win ? ['cmd.exe', '/c', command]
  \                      : ['sh', '-c', command]

 let s:runner._key = a:session.continue()
 let s:runner._job = jobstart(command, {
        \ 'on_stdout': function('s:_job_cb'),
        \ 'on_stderr': function('s:_job_cb'),
        \ 'on_exit': function('s:_job_exit_cb'),
        \ })

endfunction

function! s:sweep() abort
  if has_key(self, '_job')
    call jobstop(self.job)
  endif
endfunction

function! s:_job_cb(channel, message) abort
  " echomsg a:channel a:message s:runner
  " let ss = quickrun#session(s:runner._key, 'output', a:message)
  let session = quickrun#session(s:runner._key)
  call session.output(join(a:message, "\n"))
  " call quickrun#session.output(a:message)
endfunction

function! s:_job_exit_cb(channel, exit_status) abort
  let session = quickrun#session(s:runner._key)
  call session.finish()
endfunction

function! quickrun#runner#jobstart#new() abort
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
