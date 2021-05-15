" quickrun: outputter/null: Doesn't output.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:outputter = {}

function s:outputter.output(data, session) abort
endfunction


function quickrun#outputter#null#new() abort
  return deepcopy(s:outputter)
endfunction
