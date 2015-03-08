" quickrun: outputter/buffered: Meta outputter; Buffers the output.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'target': '',
\   },
\ }

function! s:outputter.init(session) abort
  let self._result = ''
endfunction

function! s:outputter.output(data, session) abort
  let self._result .= a:data
endfunction

function! s:outputter.finish(session) abort
  let outputter = a:session.make_module('outputter', self.config.target)
  call outputter.output(self._result, a:session)
  call outputter.finish(a:session)
endfunction


function! quickrun#outputter#buffered#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
