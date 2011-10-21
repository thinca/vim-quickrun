" Run commands quickly.
" Version: 0.5.1
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_quickrun')
  finish
endif
let g:loaded_quickrun = 1

let s:save_cpo = &cpo
set cpo&vim


command! -nargs=* -range=0 -complete=customlist,quickrun#complete QuickRun
\ call quickrun#command(<q-args>, <count>, <line1>, <line2>)


nnoremap <silent> <Plug>(quickrun-op)
\        :<C-u>set operatorfunc=quickrun#operator<CR>g@

nnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode n<CR>
vnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode v<CR>

" Default key mappings.
if !hasmapto('<Plug>(quickrun)')
\  && (!exists('g:quickrun_no_default_key_mappings')
\      || !g:quickrun_no_default_key_mappings)
  silent! map <unique> <Leader>r <Plug>(quickrun)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
