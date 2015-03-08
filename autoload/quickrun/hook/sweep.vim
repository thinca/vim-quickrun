" quickrun: hook/sweep: Sweeps temporary files.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'files': [],
\   }
\ }

function! s:hook.init(session) abort
  if empty(self.config.files)
    let self.config.enable = 0
  endif
endfunction

function! s:hook.on_ready(session, context) abort
  for file in self.config.files
    call a:session.tempname(a:session.build_command(file))
  endfor
endfunction

function! quickrun#hook#sweep#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
