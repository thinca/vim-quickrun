" quickrun: hook/output_encode: Converts the encoding of output.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'encoding': '&fileencoding',
\   },
\ }

function! s:hook.init(session) abort
  let enc = split(self.config.encoding, '[^[:alnum:]-_]')
  if len(enc) is 1
    let enc += [&encoding]
  endif
  if len(enc) is 2 && enc[0] !=# '' && enc[1] !=# '' && enc[0] !=# enc[1]
    let [self._from, self._to] = enc
  else
    let self.config.enable = 0
  endif
endfunction

function! s:hook.on_output(session, context) abort
  let a:context.data = iconv(a:context.data, self._from, self._to)
endfunction

function! quickrun#hook#output_encode#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
