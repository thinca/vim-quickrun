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

augroup plugin-quickrun-process-manager
augroup END

function! s:runner.validate()
  if !s:P.is_available()
    throw 'Needs vimproc.'
  endif
endfunction

function! s:runner.run(commands, input, session)
  let type = a:session.config.type
  let [out, err, t] = s:execute(
        \ type,
        \ a:session,
        \ a:session.runner.config.prompt,
        \ substitute(
        \   a:session.runner.config.load,
        \   '%s',
        \   a:session.config.srcfile,
        \   'g'))
  call a:session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
  if t ==# 'matched'
    return 0
  elseif t ==# 'inactive'
    call s:P.stop(type)
    call a:session.output('!!!process is inactive. try again.!!!')
    return 0
  else " 'timedout'
    let key = a:session.continue()
    augroup plugin-quickrun-process-manager
      execute 'autocmd! CursorHold,CursorHoldI * call'
      \       's:receive(' . string(key) . ')'
    augroup END
    let self._autocmd = 1
    let self._updatetime = &updatetime
    let &updatetime = 50
  endif
endfunction

function! s:execute(type, session, prompt, message)
  let cmd = printf("%s %s", a:session.config.command, a:session.config.cmdopt)
  let cmd = g:quickrun#V.iconv(cmd, &encoding, &termencoding)
  let t = s:P.touch(a:type, cmd)
  if t ==# 'new'
    call s:P.read_wait(a:type, 5.0, [a:prompt])
  elseif t ==# 'inactive'
    return ['', '', 'inactive']
  endif
  if a:message !=# ''
    call s:P.writeln(a:type, a:message)
  endif
  return s:P.read(a:type, [a:prompt])
endfunction

function! s:receive(key)
  let session = quickrun#session(a:key)

  let [out, err, t] = s:P.read(session.config.type, [session.runner.config.prompt])
  call session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
  if t ==# 'matched'
    call session.finish(1)
    return 1
  else " 'timedout'
    call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
    return 0
  endif
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

let &cpo = s:save_cpo
unlet s:save_cpo
