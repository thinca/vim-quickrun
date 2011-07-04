" quickrun: outputter: variable
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
  let name = self.config.name
  if name is ''
    throw 'Specify the variable name.'
  endif
  if name !~# '\W'
    let name = 'g:' . name
  endif
  let assign = self.config.append &&
  \            (name[0] =~# '\W' || exists(name)) ? '.=' : '='
  let self._name = name
  let self._assign = assign
  let self._size = 0
endfunction

function! s:outputter.output(data, session)
  execute 'let' self._name self._assign 'a:data'
  let self._assign = '.='
  let self._size += len(a:data)
endfunction

function! s:outputter.finish(session)
  echo printf('Output to variable "%s" (%d bytes)',
  \           self.config.name, self._size)
endfunction


function! quickrun#outputter#variable#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
