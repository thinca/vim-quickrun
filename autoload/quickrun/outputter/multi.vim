" quickrun: outputter: multi
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {
\     'targets': [],
\   },
\ }

function! s:outputter.init(session)
  let self._outputters =
  \   map(self.config.targets, 'a:session.make_module("outputter", v:val)')
endfunction

function! s:outputter.output(data, session)
  for outputter in self._outputters
    call outputter.output(a:data, a:session)
  endfor
endfunction

function! s:outputter.finish(session)
  for outputter in self._outputters
    call outputter.finish(a:session)
  endfor
endfunction


function! quickrun#outputter#multi#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
