" quickrun: runner: shell
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>


let s:save_cpo = &cpo
set cpo&vim

let s:runner = {
\   'config': {
\     'shellcmd': &shell =~? 'cmd\.exe' ? 'silent !%s & pause ' : '!%s',
\   }
\ }

function! s:runner.init(session)
  let a:session.config.outputter = 'null'
endfunction

function! s:runner.run(commands, input, session)
  if a:input !=# ''
    let inputfile = tempname()
    call writefile(split(a:input, "\n", 1), inputfile, 'b')
    let a:session._temp_input = inputfile
  endif

  for cmd in a:commands
    if cmd =~# '^\s*:'
      " A vim command.
      call quickrun#execute(cmd)
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

function! s:is_cmd_exe()
  return &shell =~? 'cmd\.exe'
endfunction

function! s:execute(cmd)
  try
    if s:is_cmd_exe()
      let sxq = &shellxquote
      let &shellxquote = '"'
    endif
    execute iconv(a:cmd, &encoding, &termencoding)
  finally
    if s:is_cmd_exe()
      let &shellxquote = sxq
    endif
  endtry
endfunction


function! quickrun#runner#shell#new()
  return copy(s:runner)
endfunction

let &cpo = s:save_cpo
