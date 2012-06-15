" quickrun: outputter/null: Doesn't output.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {}

function! s:outputter.output(data, session)
endfunction


function! quickrun#outputter#null#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
