" quickrun: hook/eval: Converts to evaluable code.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'enable': 0,
\     'template': '',
\   }
\ }

function! s:hook.init(session) abort
  if self.config.template !~# '%s'
    let self.config.enable = 0
  endif
endfunction

function! s:hook.on_module_loaded(session, context) abort
  let src = join(readfile(a:session.config.srcfile, 'b'), "\n")
  let new_src = printf(self.config.template, src)
  let srcfile = a:session.tempname()
  if writefile(split(new_src, "\n", 1), srcfile, 'b') == 0
    let a:session.config.srcfile = srcfile
  endif
endfunction

function! quickrun#hook#eval#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
