" quickrun: outputter/loclist: Outputs to location list.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = quickrun#outputter#quickfix#new()
let s:outputter.config.open_cmd = 'lopen'

function! s:outputter._apply_result(expr) abort
  lgetexpr a:expr
  return getloclist(0)
endfunction

function! s:outputter._apply_result_list(result_list) abort
  call setloclist(0, a:result_list)
endfunction

function! s:outputter._close_window() abort
  lclose
endfunction


function! quickrun#outputter#loclist#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
