" quickrun: outputter/variable: Outputs to a variable.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:outputter = {
\   'config': {
\     'name': '',
\     'append': 0,
\   },
\   'config_order': ['name', 'append'],
\ }

function s:outputter.init(session) abort
  let name = self.config.name
  if name is# ''
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

function s:outputter.output(data, session) abort
  execute 'let' self._name self._assign 'a:data'
  let self._assign = '.='
  let self._size += len(a:data)
endfunction

function s:outputter.finish(session) abort
  echo printf('Output to variable "%s" (%d bytes)',
  \           self.config.name, self._size)
endfunction


function quickrun#outputter#variable#new() abort
  return deepcopy(s:outputter)
endfunction
