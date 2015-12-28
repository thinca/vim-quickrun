" quickrun: outputter/quickfix: Outputs to quickfix.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:VT = g:quickrun#V.import('Vim.ViewTracer')

let s:outputter = quickrun#outputter#buffered#new()
let s:outputter.config = {
\   'errorformat': '',
\   'open_cmd': 'copen',
\   'into': 0,
\ }

let s:outputter.init_buffered = s:outputter.init

function! s:outputter.init(session) abort
  call self.init_buffered(a:session)
  let self.config.errorformat
\    = !empty(self.config.errorformat) ? self.config.errorformat
\    : !empty(&l:errorformat)          ? &l:errorformat
\    : &g:errorformat
endfunction


function! s:outputter.finish(session) abort
  try
    let errorformat = &g:errorformat
    let &g:errorformat = self.config.errorformat
    cgetexpr self._result
    let win = s:VT.trace_window()
    execute self.config.open_cmd
    if &buftype ==# 'quickfix'
      let w:quickfix_title = 'quickrun: ' .  join(a:session.commands, ' && ')
    endif
    let result_empty = len(getqflist()) == 0
    if result_empty
      cclose
    endif
    if result_empty || !self.config.into
      call s:VT.jump(win)
    endif
  finally
    let &g:errorformat = errorformat
  endtry
endfunction


function! quickrun#outputter#quickfix#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
