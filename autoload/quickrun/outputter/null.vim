" quickrun: outputter: null
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {}

function! s:outputter.output(data, session)
endfunction


function! quickrun#outputter#null#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
