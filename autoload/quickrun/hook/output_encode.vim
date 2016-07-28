" quickrun: hook/output_encode: Converts the encoding of output.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'encoding': '&fileencoding',
\     'fileformat': 0,
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
    let [self._from, self._to] = ['', '']
  endif
  if self._from ==# '' && !self.config.fileformat
    let self.config.enable = 0
  endif
endfunction

function! s:hook.on_output(session, context) abort
  let data = a:context.data
  if self._from !=# ''
    let data = iconv(data, self._from, self._to)
  endif
  if self.config.fileformat
    let data = substitute(data, '\r\n\?', '\n', 'g')
  endif
  let a:context.data = data
endfunction

function! quickrun#hook#output_encode#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
