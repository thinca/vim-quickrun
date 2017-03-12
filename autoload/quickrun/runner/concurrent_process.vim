" quickrun: runner/concurrent_process: Runs by Vital.ConcurrentProcess
" Author:  ujihisa <ujihisa at gmail com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {
\   'config': {
\     'load': 'load %s',
\     'prompt': '>>> ',
\   }
\ }

let s:M = g:quickrun#V.import('Vim.Message')
let s:B = g:quickrun#V.import('Vim.Buffer')
let s:CP = g:quickrun#V.import('ConcurrentProcess')

augroup plugin-quickrun-concurrent-process
augroup END

function! s:runner.validate() abort
  if !s:CP.is_available()
    throw 'Needs vimproc.'
  endif
endfunction

function! s:runner.run(commands, input, session) abort
  let type = a:session.config.type

  let message = a:session.build_command(self.config.load)
  if message ==# ''
    return 0
  endif

  let cmd = printf('%s %s', a:session.config.command, a:session.config.cmdopt)
  let cmd = g:quickrun#V.Process.iconv(cmd, &encoding, &termencoding)

  let label = s:CP.of(cmd, '', [
        \ ['*read*', '_', self.config.prompt]])

  if s:CP.is_done(label, 'x')
    call s:CP.queue(label, [
          \ ['*writeln*', message],
          \ ['*read*', 'x', self.config.prompt]])
  else
    call s:CP.shutdown(label)
    call s:M.warn("Previous process was still running. Restarted.")
    " TODO be dry, or use ConcurrentProcess' new feature
    let label = s:CP.of(cmd, '', [
          \ ['*read*', '_', self.config.prompt]])
    call s:CP.queue(label, [
          \ ['*writeln*', message],
          \ ['*read*', 'x', self.config.prompt]])
  endif

  let a:session._cmd = cmd
  let a:session._prompt = self.config.prompt
  let key = a:session.continue()
  augroup plugin-quickrun-concurrent-process
    execute 'autocmd! CursorHold,CursorHoldI * call'
    \       's:receive(' . string(key) . ')'
  augroup END
  let self._autocmd = 1
  let self._updatetime = &updatetime
  let &updatetime = 50
endfunction

function! s:receive(key) abort
  if s:B.is_cmdwin()
    return 0
  endif

  let session = quickrun#session(a:key)
  let label = s:CP.of(session._cmd, '', [['*read*', '_', session._prompt]])
  let [out, err] = s:CP.consume(label, 'x')
  call session.output(out . (err ==# '' ? '' : printf('!!!%s!!!', err)))
  if s:CP.is_done(label, 'x')
    call session.finish(1)
    return 1
  endif

  call quickrun#trigger_keys()
  return 0
endfunction

function! s:runner.sweep() abort
  if has_key(self, '_autocmd')
    autocmd! plugin-quickrun-concurrent-process
  endif
  if has_key(self, '_updatetime')
    let &updatetime = self._updatetime
  endif
endfunction

function! quickrun#runner#concurrent_process#new() abort
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
