" quickrun: outputter: echo
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'name': 'echo',
\ }

function! s:outputter.output(data, session)
  echon a:data
endfunction


function! quickrun#outputter#echo#new()
  return copy(s:outputter)
endfunction

let &cpo = s:save_cpo
