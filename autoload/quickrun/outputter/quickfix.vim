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
  let self._target_window = s:VT.trace_window()
endfunction


function! s:outputter.finish(session) abort
  try
    let errorformat = &g:errorformat
    let &g:errorformat = self.config.errorformat
    let current_window = s:VT.trace_window()
    call s:VT.jump(self._target_window)
    let result_list = self._apply_result(self._result)
    execute self.config.open_cmd
    if &buftype ==# 'quickfix'
      let w:quickfix_title = 'quickrun: ' .  join(a:session.commands, ' && ')
    endif
    let result_empty = len(result_list) == 0
    if result_empty
      call self._close_window()
    endif
    call s:VT.jump(self._target_window)
    if !self.config.into
      call s:VT.jump(current_window)
    endif
  finally
    let &g:errorformat = errorformat
  endtry
endfunction

function! s:outputter._apply_result(expr) abort
  cgetexpr a:expr
  return getqflist()
endfunction

function! s:outputter._close_window() abort
  cclose
endfunction


function! quickrun#outputter#quickfix#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
