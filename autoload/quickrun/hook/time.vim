" quickrun: hook/time: Measures execution time.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'enable': 0,
\     'format': "\n*** time: %g ***",
\     'dest': '',
\   },
\ }

function! s:hook.init(session) abort
  if self.config.enable && !empty(self.config.dest)
    let self._outputter = a:session.make_module('outputter', self.config.dest)
  endif
endfunction

function! s:hook.on_ready(session, context) abort
  let self._start = reltime()
endfunction

function! s:hook.on_finish(session, context) abort
  let self._end = reltime()
  let time = str2float(reltimestr(reltime(self._start, self._end)))
  let text = printf(self.config.format, time)
  if has_key(self, '_outputter')
    call self._outputter.output(text, a:session)
    call self._outputter.finish(a:session)
  else
    call a:session.output(text)
  endif
endfunction

function! quickrun#hook#time#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
