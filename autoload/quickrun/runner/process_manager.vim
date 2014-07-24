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

function! s:runner.validate()
  if !s:P.is_available()
    throw 'Needs vimproc.'
  endif
endfunction

function! s:runner.run(commands, input, session)
  let type = a:session.config.type

  if s:last_process_type !=# '' && s:P.state(s:last_process_type) == 'reading'
    call a:session.output('!!!Hey wait.. Cancelling previous request. Try again after a while!!!')
    let [_, _, t] = s:P.read(s:last_process_type, [self.config.prompt])
    if t ==# 'matched'
    endif
    return 0
  endif

  let s:last_process_type = type

  let message = a:session.build_command(self.config.load)
  let [out, err, t] = s:execute(
        \ type,
        \ a:session,
        \ self.config.prompt,
        \ message)
  call a:session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
  if t ==# 'matched'
    return 0
  elseif t ==# 'inactive'
    call s:P.kill(type)
    call a:session.output('!!!process is inactive. try again.!!!')
    return 0
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

function! s:execute(type, session, prompt, message)
  let cmd = printf("%s %s", a:session.config.command, a:session.config.cmdopt)
  let cmd = g:quickrun#V.Process.iconv(cmd, &encoding, &termencoding)
  let t = s:P.touch(a:type, cmd)
  if t ==# 'new'
    return ['', '', 'preparing']
  elseif t ==# 'existing'
    if a:message !=# ''
      call s:P.writeln(a:type, a:message)
    endif
    return s:P.read(a:type, [a:prompt])
  else
    throw 'Must not happen -- bug in ProcessManager.'
  endif
endfunction

function! s:receive(key)
  if s:_is_cmdwin()
    return 0
  endif

  let session = quickrun#session(a:key)
  if session.runner.phase == 'ready'
    let [out, err, t] = s:P.read(session.config.type, [session.runner.config.prompt])
    call session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
    if t ==# 'matched'
      call session.finish(1)
      return 1
    else " 'timedout'
      " nop
    endif
  elseif session.runner.phase == 'preparing'
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

  call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
  return 0
endfunction

function! s:runner.sweep()
  if has_key(self, '_autocmd')
    autocmd! plugin-quickrun-process-manager
  endif
  if has_key(self, '_updatetime')
    let &updatetime = self._updatetime
  endif
endfunction

function! quickrun#runner#process_manager#new()
  return deepcopy(s:runner)
endfunction

function! quickrun#runner#process_manager#kill()
  call s:P.kill(s:last_process_type)
endfunction

" TODO use vital's
function! s:_is_cmdwin()
  return bufname('%') ==# '[Command Line]'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
