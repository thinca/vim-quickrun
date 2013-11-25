" quickrun: hook/rsystem: Run file using ssh and rsync.
" Author : joelmo
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'rhost' : '',
\     'rdir' : '',
\     'enable' : 0
\   },
\ }

function! s:hook.init(session)
  if empty(self.config.rdir)
    let self.config.rdir = fnamemodify(tempname(), ':h') . '/'
  endif
  let self.config.enable = !empty(self.config.rhost)
endfunction

function! s:hook.on_module_loaded(session, context)
  let exec = a:session.config.exec
  let i = len(exec)
  while i
    let i -= 1
    let exec[i] = substitute(exec[i], '%c', a:session.config.command, '')
  endwhile
  let a:session.config.exec = exec
endfunction

function! s:hook.on_ready(session, context)
  let sync = 'rsync -WR ' . a:session.config.srcfile . ' '. 
	\ self.config.rhost . ':' . self.config.rdir
  let cmds = 'ssh ' . self.config.rhost .
	\ join([' cd ' . self.config.rdir
	\ . fnamemodify(a:session.config.srcfile,':h')]
	\ + a:session.commands, '&&')
  let a:session.commands = [sync, cmds]
  let a:session.outputter.config.name = '*qrun* ' . self.config.rhost
endfunction

function! quickrun#hook#rsystem#new()
  return s:hook
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
