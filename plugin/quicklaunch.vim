" Launch the registered command in quickly.
" Version: 0.1.0.1
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_quicklaunch') || v:version < 702
  finish
endif
let g:loaded_quicklaunch = 1

let s:save_cpo = &cpo
set cpo&vim



function! s:quicklaunch(no)
  if !exists(':QuickRun')
    echoerr ':QuickRun command is not defined.'
  endif

  if !exists('g:quicklaunch_commands[a:no]')
  \  || type(g:quicklaunch_commands[a:no]) != type('')
  \  || g:quicklaunch_commands[a:no] == ''
    echoerr 'quicklaunch has no such command:' a:no
    return
  endif

  execute 'QuickRun' '-exec' '"' . substitute(
  \       g:quicklaunch_commands[a:no], '"', '\\"', 'g') . '"' '>'
endfunction



function! s:quicklaunch_list()
  if !exists('g:quicklaunch_commands')
    echo 'no command registered'
    return
  endif
  for i in range(10)
    echo i . ': ' . (exists('g:quicklaunch_commands[i]') ? g:quicklaunch_commands[i] : '<Nop>')
  endfor
endfunction



function! s:define_interface_key_mappings()
  for i in range(10)
    execute 'nnoremap <silent> <Plug>(quicklaunch-' . i . ')'
    \                         ':<C-u>call <SID>quicklaunch(' . i . ')<CR>'
  endfor

  nnoremap <silent> <Plug>(quicklaunch-list)
  \                 :<C-u>QuickRun -exec ':call <SID>quicklaunch_list()' ><CR>
endfunction



function! s:define_default_key_mappings()
  for i in range(10)
    execute 'silent! nmap <unique> <Leader>' . i
    \                        '<Plug>(quicklaunch-' . i . ')'
  endfor

  silent! nmap <unique> <Leader>l <Plug>(quicklaunch-list)
endfunction



call s:define_interface_key_mappings()

if !exists('g:quicklaunch_no_default_key_mappings')
\  || !g:quicklaunch_no_default_key_mappings
  call s:define_default_key_mappings()
endif



let &cpo = s:save_cpo
unlet s:save_cpo
