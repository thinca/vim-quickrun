" quickrun: outputter: file
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'name': '',
\     'append': 0,
\   },
\   'config_order': ['name', 'append'],
\ }

function! s:outputter.init(session)
  let file = self.config.name
  if file is ''
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

function! s:outputter.output(data, session)
  execute 'redir >> ' . self._file
  silent! echon a:data
  redir END
  let self._size += len(a:data)
endfunction

function! s:outputter.finish(session)
  echo printf('Output to "%s" (%d bytes)', self.config.name, self._size)
endfunction


function! quickrun#outputter#file#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
