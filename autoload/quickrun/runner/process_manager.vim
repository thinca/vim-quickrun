" quickrun: runner/process_manager: Runs by Vital.ProcessManager
" Author:  ujihisa <ujihisa at gmail com>
" License: zlib License
" Known issues:
"   * if a run stalled, next run will wait. It should cancel previous one
"   automatically.
"   * kill interface doesn't exist yet (related to the previous issue)

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {
\   'config': {
\     'load': 'load %s',
\     'prompt': '>>> ',
\   }
\ }

let s:P = g:quickrun#V.import('ProcessManager')

" The filetype of the process you ran last time
let s:last_process_type = ''

augroup plugin-quickrun-process-manager
augroup END

function! s:runner.validate() abort
  if !s:P.is_available()
    throw 'Needs vimproc.'
  endif
endfunction

function! s:runner.run(commands, input, session) abort
  let type = a:session.config.type

  let message = a:session.build_command(self.config.load)
  if message ==# ''
    return 0
  endif

  if s:last_process_type !=# '' && s:P.state(s:last_process_type) ==# 'reading'
    call a:session.output('!!!Hey wait.. Cancelling previous request. Try again!!!')
    call s:P.kill(s:last_process_type)
    return 0
  endif

  let s:last_process_type = type

  let cmd = printf('%s %s', a:session.config.command, a:session.config.cmdopt)
  let cmd = g:quickrun#V.Process.iconv(cmd, &encoding, &termencoding)
  call s:P.touch(type, cmd)
  let state = s:P.state(type)
  if state ==# 'undefined' || state ==# 'inactive'
    let t = 'preparing'
  elseif state ==# 'idle'
    call s:P.writeln(type, message)
    let [out, err, t] = s:P.read(type, [self.config.prompt])
    call a:session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
  else " 'reading' is already checked
    throw 'Must not happen -- bug in ProcessManager.'
  endif

  if t ==# 'matched'
    return 0
  elseif t ==# 'inactive'
    call s:P.kill(type)
    call g:quickrun#V.Vim.Message.warn('process is inactive. Restarting...')
    call a:session.finish()
    return a:session.run()
  elseif t ==# 'timedout' || t ==# 'preparing'
    let key = a:session.continue()
    augroup plugin-quickrun-process-manager
      execute 'autocmd! CursorHold,CursorHoldI * call'
      \       's:receive(' . string(key) . ')'
    augroup END
    if t ==# 'preparing'
      let self.phase = 'preparing'
      let self._message = message
    else
      let self.phase = 'ready'
    endif
    let self._autocmd = 1
    let self._updatetime = &updatetime
    let &updatetime = 50
  else
    call a:session.output(printf('Must not happen. t: %s', t))
    return 0
  endif
endfunction

function! s:receive(key) abort
  if s:_is_cmdwin()
    return 0
  endif

  let session = quickrun#session(a:key)
  if session.runner.phase ==# 'ready'
    let [out, err, t] = s:P.read(session.config.type, [session.runner.config.prompt])
    call session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
    if t ==# 'matched'
      call session.finish(1)
      return 1
    else " 'timedout'
      " nop
    endif
  elseif session.runner.phase ==# 'preparing'
    let [out, err, t] = s:P.read(session.config.type, [session.runner.config.prompt])
    if t ==# 'matched'
      let session.runner.phase = 'ready'
      call s:P.writeln(session.config.type, session.runner._message)
      unlet session.runner._message
    else
      " silently ignore preparation outputs
    endif
  else
    call session.output(printf(
          \ 'Must not happen -- it should be unreachable. phase: %s',
          \ session.runner.phase))
  endif

  call quickrun#trigger_keys()
  return 0
endfunction

function! s:runner.sweep() abort
  if has_key(self, '_autocmd')
    autocmd! plugin-quickrun-process-manager
  endif
  if has_key(self, '_updatetime')
    let &updatetime = self._updatetime
  endif
endfunction

function! quickrun#runner#process_manager#new() abort
  return deepcopy(s:runner)
endfunction

function! quickrun#runner#process_manager#kill() abort
  call s:P.kill(s:last_process_type)
endfunction

" TODO use vital's
function! s:_is_cmdwin() abort
  return bufname('%') ==# '[Command Line]'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
