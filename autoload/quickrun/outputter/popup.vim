" quickrun: outputter/popup: Outputs to a popup window.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License


let s:outputter = quickrun#outputter#buffered#new()

let s:winid = 0

function! s:outputter.validate() abort
  if !exists('*popup_create')
    throw 'Needs popup feature.'
  endif
endfunction

function! s:outputter.finish(session) abort
  if s:winid
    call popup_close(s:winid)
  endif
  let result = split(self._result, "\n")
  let width = max(map(copy(result), { _, l -> strwidth(l) }))
  let s:winid = popup_create(result, {'minwidth': width})
endfunction

function! quickrun#outputter#popup#new() abort
  return deepcopy(s:outputter)
endfunction

augroup plugin-quickrun-outputter-popup
  autocmd!
  autocmd CursorMoved,CursorMovedI,InsertEnter,InsertLeave,WinEnter *
  \ if 0 < s:winid | call popup_close(s:winid) | let s:winid = 0 | endif
augroup END
