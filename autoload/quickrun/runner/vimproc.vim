" quickrun: runner/vimproc: Runs by vimproc at background.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

" Create augroup.
augroup plugin-quickrun-vimproc
augroup END

let s:runner = {
\   'config': {
\     'updatetime': 0,
\     'sleep': 50,
\   }
\ }

function! s:runner.validate()
  if globpath(&runtimepath, 'autoload/vimproc.vim') ==# ''
    throw 'Needs vimproc.'
  endif
endfunction

function! s:runner.run(commands, input, session)
  let vimproc = vimproc#pgroup_open(join(a:commands, ' && '))
  call vimproc.stdin.write(a:input)
  call vimproc.stdin.close()

  let a:session._vimproc = vimproc
  let key = a:session.continue()

  " Wait a little because execution might end immediately.
  if self.config.sleep
    execute 'sleep' self.config.sleep . 'm'
  endif
  if s:receive_vimproc_result(key)
    return
  endif
  " Execution is continuing.
  augroup plugin-quickrun-runner-vimproc
    execute 'autocmd! CursorHold,CursorHoldI * call'
    \       's:receive_vimproc_result(' . string(key) . ')'
  augroup END
  let self._autocmd = 1
  if self.config.updatetime
    let self._updatetime = &updatetime
    let &updatetime = self.config.updatetime
  endif
endfunction

function! s:runner.shellescape(str)
  return '"' . escape(a:str, '\"') . '"'
endfunction

function! s:runner.sweep()
  if has_key(self, '_autocmd')
    autocmd! plugin-quickrun-runner-vimproc
  endif
  if has_key(self, '_updatetime')
    let &updatetime = self._updatetime
  endif
endfunction


function! s:receive_vimproc_result(key)
  let session = quickrun#session(a:key)

  let vimproc = session._vimproc

  try
    if !vimproc.stdout.eof
      call session.output(vimproc.stdout.read())
    endif
    if !vimproc.stderr.eof
      call session.output(vimproc.stderr.read())
    endif

    if !(vimproc.stdout.eof && vimproc.stderr.eof)
      call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
      return 0
    endif
  catch
    " XXX: How is an internal error displayed?
    call session.output(
    \    'quickrun: vimproc: ' . v:throwpoint . "\n" . v:exception)
  endtry

  call vimproc.stdout.close()
  call vimproc.stderr.close()
  call vimproc.waitpid()
  call session.finish(get(vimproc, 'status', 1))
  return 1
endfunction


function! quickrun#runner#vimproc#new()
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
