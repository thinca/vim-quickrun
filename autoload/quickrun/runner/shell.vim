" quickrun: runner/shell: Runs by :! .
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License


let s:save_cpo = &cpo
set cpo&vim

let s:runner = {
\   'config': {
\     'shellcmd': &shell =~? 'cmd\.exe' ? 'silent !%s & pause ' : '!%s',
\   }
\ }

function! s:runner.init(session) abort
  let a:session.config.outputter = 'null'
endfunction

function! s:runner.run(commands, input, session) abort
  if a:input !=# ''
    let inputfile = a:session.tempname()
    call writefile(split(a:input, "\n", 1), inputfile, 'b')
  endif

  for cmd in a:commands
    if cmd =~# '^\s*:'
      " A vim command.
      try
        execute cmd
      catch
        break
      endtry
      continue
    endif

    if a:input !=# ''
      let cmd .= ' <' . self.shellescape(inputfile)
    endif

    call s:execute(printf(self.config.shellcmd, cmd))
    if v:shell_error != 0
      break
    endif
  endfor
endfunction

function! s:execute(cmd) abort
  let is_cmd_exe = &shell =~? 'cmd\.exe'
  try
    if is_cmd_exe
      let sxq = &shellxquote
      let &shellxquote = '"'
    endif
    execute g:quickrun#V.Process.iconv(a:cmd, &encoding, &termencoding)
  finally
    if is_cmd_exe
      let &shellxquote = sxq
    endif
  endtry
endfunction


function! quickrun#runner#shell#new() abort
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
