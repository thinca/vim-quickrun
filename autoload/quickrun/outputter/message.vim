" quickrun: outputter: echo
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = {
\   'name': 'message',
\ }

function! s:outputter.init(args, session)
  let self._log = a:session.config.append
  let self._buf = ''
endfunction

function! s:outputter.output(data, session)
  if !self._log
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

function! s:outputter.finish(session)
  if self._log
    echomsg self._buf
  endif
endfunction


function! quickrun#outputter#message#new()
  return copy(s:outputter)
endfunction

let &cpo = s:save_cpo
