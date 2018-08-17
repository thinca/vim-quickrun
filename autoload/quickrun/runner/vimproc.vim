" quickrun: runner/vimproc: Runs by vimproc at background.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

" Create augroup.
augroup plugin-quickrun-runner-vimproc
augroup END

let s:runner = {
\   'config': {
\     'updatetime': 0,
\     'sleep': 50,
\     'read_timeout': 100,
\     'pipe_status_index': -1,
\   }
\ }
let s:bufsize = -1

let s:M = g:quickrun#V.import('Vim.Message')

function! s:runner.validate() abort
  if globpath(&runtimepath, 'autoload/vimproc.vim') ==# ''
    throw 'Needs vimproc.'
  endif
endfunction

function! s:runner.init(session) abort
  if type(self.config.pipe_status_index) !=# type(0) &&
  \  string(self.config.pipe_status_index) !=# string('pipefail')
    call s:M.warn("Invalid value in `runner/vimproc/pipe_status_index`: "
    \            .string(self.config.pipe_status_index))
    let self.config.pipe_status_index = -1
  endif
endfunction

function! s:runner.run(commands, input, session) abort
  let vimproc = vimproc#pgroup_open(join(a:commands, ' && '))
  call vimproc.stdin.write(a:input)
  call vimproc.stdin.close()

  let a:session._vimproc = vimproc
  let key = a:session.continue()

  " Wait a little because execution might end immediately.
  if self.config.sleep
    execute 'sleep' self.config.sleep . 'm'
  endif
  if s:receive_vimproc_result(key, self.config.read_timeout,
  \                           self.config.pipe_status_index)
    return
  endif
  " Execution is continuing.
  augroup plugin-quickrun-runner-vimproc
    execute 'autocmd! CursorHold,CursorHoldI * call'
    \       's:receive_vimproc_result(' . string(key) . ','
    \         string(self.config.read_timeout) . ','
    \         string(self.config.pipe_status_index) . ')'
  augroup END
  let self._autocmd = 1
  if self.config.updatetime
    let self._updatetime = &updatetime
    let &updatetime = self.config.updatetime
  endif
endfunction

function! s:runner.shellescape(str) abort
  return '"' . escape(a:str, '\"') . '"'
endfunction

function! s:runner.sweep() abort
  if has_key(self, '_autocmd')
    autocmd! plugin-quickrun-runner-vimproc
  endif
  if has_key(self, '_updatetime')
    let &updatetime = self._updatetime
  endif
endfunction


function! s:receive_vimproc_result(key, read_timeout, pipe_status_index) abort
  let session = quickrun#session(a:key)

  let vimproc = session._vimproc

  try
    if !vimproc.stdout.eof
      call session.output(vimproc.stdout.read(s:bufsize, a:read_timeout))
    endif
    if !vimproc.stderr.eof
      call session.output(vimproc.stderr.read(s:bufsize, a:read_timeout))
    endif

    if !(vimproc.stdout.eof && vimproc.stderr.eof)
      call quickrun#trigger_keys()
      return 0
    endif
  catch
    " XXX: How is an internal error displayed?
    call session.output(
    \    'quickrun: vimproc: ' . v:throwpoint . "\n" . v:exception)
  endtry

  call vimproc.stdout.close()
  call vimproc.stderr.close()
  let status = vimproc.waitpid()[1]
  if has_key(vimproc, 'pipe_status')
    let session.pipe_status = map(copy(vimproc.pipe_status), 'v:val[1]')
    if string(a:pipe_status_index) ==# string('pipefail')
      let status = get(filter(copy(session.pipe_status), 'v:val'), -1, 0)
    else
      let status = get(session.pipe_status, a:pipe_status_index, status)
    endif
  endif
  call session.finish(status)
  return 1
endfunction


function! quickrun#runner#vimproc#new() abort
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
