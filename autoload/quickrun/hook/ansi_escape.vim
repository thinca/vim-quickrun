" quickrun: hook/ansi_escape Measures execution time.
" Author : Zhao Cai <caizhaoff@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
    \   'config': {
    \     'enable': 0,
    \   },
    \ }

function! s:hook.init(session)
  if self.config.enable && !exists(":AnsiEsc")
    echohl ErrorMsg
    echomsg "quickrun: outputter/buffer: AnsiEsc plugin is reqired for ansi_esacpe."
    echohl NONE
  endif
endfunction

function! s:hook.on_exit(session, context)
  call s:in_outputter_buffer(a:session, "call s:ansi_escape()")
endfunction

function! s:in_outputter_buffer(session, command)
  let outputter_bufnr = get(a:session.outputter, 'bufnr', 0)
  if outputter_bufnr == 0
    return
  endif

  let winnr = winnr()
  let outputter_winnr = bufwinnr(outputter_bufnr)
  if winnr != outputter_winnr
    execute outputter_winnr 'wincmd w'
  endif

  exec a:command

  if winnr != outputter_winnr
    wincmd p
  endif
endfunction

function! s:ansi_escape()
  if !get(b:,'ansi_escape_enabled', 0)
    AnsiEsc
    let b:ansi_escape_enabled = 1
  endif
endfunction

function! quickrun#hook#ansi_escape#new()
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

