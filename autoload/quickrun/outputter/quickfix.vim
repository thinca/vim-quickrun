" quickrun: outputter: quickfix
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:outputter = quickrun#outputter#buffered#new()
let s:outputter.config = {
\   'errorformat': '&errorformat',
\ }

function! s:outputter.finish(session)
  try
    let errorformat = &l:errorformat
    let &l:errorformat = self.config.errorformat
    cgetexpr self._result
    cwindow
    for winnr in range(1, winnr('$'))
      if getwinvar(winnr, '&buftype') ==# 'quickfix'
        call setwinvar(winnr, 'quickfix_title', 'quickrun: ' .
        \   join(a:session.commands, ' && '))
        break
      endif
    endfor
  finally
    let &l:errorformat = errorformat
  endtry
endfunction


function! quickrun#outputter#quickfix#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
