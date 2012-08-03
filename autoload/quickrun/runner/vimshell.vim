" quickrun: runner/system: Runs by system().
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {}

function! s:runner.run(commands, input, session)
  let code = 0
  if !exists(":VimShellSendString")
      call g:quickrun#V.print_error("Please activate vimshell first!")
      let code = 1
      return code
  endif

  for cmd in a:commands
      execute "VimShellSendString " . cmd
  endfor
  return code
endfunction



function! quickrun#runner#vimshell#new()
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
