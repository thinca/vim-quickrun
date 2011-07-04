" quickrun: outputter: buffered
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'target': '',
\   },
\ }

function! s:outputter.init(session)
  let self._result = ''
endfunction

function! s:outputter.output(data, session)
  let self._result .= a:data
endfunction

function! s:outputter.finish(session)
  let outputter = a:session.make_module('outputter', self.config.target)
  call outputter.output(self._result, a:session)
  call outputter.finish(a:session)
endfunction


function! quickrun#outputter#buffered#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
