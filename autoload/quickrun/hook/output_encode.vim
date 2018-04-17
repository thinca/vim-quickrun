" quickrun: hook/output_encode: Converts the encoding of output.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'encoding': '&fileencoding',
\     'fileformat': '',
\   },
\  '_fileformats': {'unix': "\n", 'dos': "\r\n", 'mac': "\r"},
\ }

let s:M = g:quickrun#V.import('Vim.Message')

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
  let self._eol = get(self._fileformats, self.config.fileformat, '')
  if self.config.fileformat !=# '' && self._eol ==# ''
    call s:M.warn("Invalid type in `hook/output_encode/fileformat`.")
  endif
  if self._from ==# '' && self._eol ==# ''
    let self.config.enable = 0
  endif
endfunction

function! s:hook.on_output(session, context) abort
  let data = a:context.data
  if self._from !=# ''
    let data = iconv(data, self._from, self._to)
  endif
  if self._eol !=# ''
    let data = substitute(data, '\r\n\?\|\n', self._eol, 'g')
  endif
  let a:context.data = data
endfunction

function! quickrun#hook#output_encode#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
