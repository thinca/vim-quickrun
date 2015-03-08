" quickrun: outputter/message: Outputs to messages area.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'config': {'log': 0},
\ }

function! s:outputter.init(session) abort
  let self._buf = ''
endfunction

function! s:outputter.output(data, session) abort
  if !self.config.log
    echon a:data
    return
  endif
  let lines = split(a:data, "\n", 1)
  let lines[0] = self._buf . lines[0]
  let self._buf = lines[-1]
  for line in lines[: -2]
    echomsg line
  endfor
endfunction

function! s:outputter.finish(session) abort
  if self.config.log && self._buf !=# ''
    echomsg self._buf
  endif
endfunction


function! quickrun#outputter#message#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
