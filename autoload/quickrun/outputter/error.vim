" quickrun: outputter/error: Meta outputter; Switches outputters by result.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = quickrun#outputter#buffered#new()
let s:outputter.config = {
\   'success': 'null',
\   'error': 'null',
\ }
let s:outputter.config_order = ['success', 'error']

function! s:outputter.finish(session) abort
  let outputter = a:session.make_module('outputter',
  \   self.config[a:session.exit_code ? 'error' : 'success'])
  call outputter.start(a:session)
  call outputter.output(self._result, a:session)
  call outputter.finish(a:session)
endfunction


function! quickrun#outputter#error#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
