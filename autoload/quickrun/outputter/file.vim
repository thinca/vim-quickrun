" quickrun: outputter/file: Outputs to a file.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'name': '',
\     'append': 0,
\   },
\   'config_order': ['name', 'append'],
\ }

function! s:outputter.init(session) abort
  let file = self.config.name
  if file is# ''
    throw 'Specify the file.'
  endif
  if isdirectory(file)
    throw 'Target is a directory.'
  endif
  if !self.config.append && filereadable(file)
    call delete(file)
  endif
  let self._file = fnamemodify(file, ':p')
  let self._size = 0
endfunction

function! s:outputter.output(data, session) abort
  execute 'redir >> ' . self._file
  silent! echon a:data
  redir END
  let self._size += len(a:data)
endfunction

function! s:outputter.finish(session) abort
  echo printf('Output to "%s" (%d bytes)', self.config.name, self._size)
endfunction


function! quickrun#outputter#file#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
