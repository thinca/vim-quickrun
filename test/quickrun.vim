scriptencoding utf-8

let s:sute = themis#suite('quickrun')
let s:assert = themis#helper('assert')


function! s:sute.default_config() abort
  call s:assert.is_dict(g:quickrun#default_config)
endfunction
