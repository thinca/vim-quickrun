" Run commands quickly.
" Version: 0.4.1
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_quickrun')
  finish
endif
let g:loaded_quickrun = 1

let s:save_cpo = &cpo
set cpo&vim

" MISC Functions. {{{1
" ----------------------------------------------------------------------------
" Function for |g@|.
function! QuickRun(mode)  " {{{2
  execute 'QuickRun -mode o -visualmode' a:mode
endfunction



function! s:is_win()  " {{{2
  return has('win32') || has('win64')
endfunction



" ----------------------------------------------------------------------------
" Initialize. {{{1
function! s:init()
  let g:quickrun_default_config = {
        \ '*': {
        \   'shebang': 1,
        \   'output': '',
        \   'append': 0,
        \   'runmode': 'simple',
        \   'args': '',
        \   'output_encode': '&fenc:&enc',
        \   'tempfile'  : '{tempname()}',
        \   'exec': '%c %s %a',
        \   'split': '{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
        \   'into': 0,
        \   'eval': 0,
        \   'eval_template': '%s',
        \   'shellcmd': s:is_win() ? 'silent !"%s" & pause' : '!%s',
        \   'running_mark': ':-)',
        \ },
        \ 'awk': {
        \   'exec': '%c -f %s %a',
        \ },
        \ 'bash': {},
        \ 'c':
        \   s:is_win() && executable('cl') ? {
        \     'command': 'cl',
        \     'exec': ['%c %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
        \               '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
        \     'tempfile': '{tempname()}.c',
        \   } :
        \   executable('gcc') ? {
        \     'command': 'gcc',
        \     'exec': ['%c %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
        \     'tempfile': '{tempname()}.c',
        \   } : {},
        \ 'cpp':
        \   s:is_win() && executable('cl') ? {
        \     'command': 'cl',
        \     'exec': ['%c %s /nologo /Fo%s:p:r.obj /Fe%s:p:r.exe > nul',
        \               '%s:p:r.exe %a', 'del %s:p:r.exe %s:p:r.obj'],
        \     'tempfile': '{tempname()}.cpp',
        \   } :
        \   executable('g++') ? {
        \     'command': 'g++',
        \     'exec': ['%c %s -o %s:p:r', '%s:p:r %a', 'rm -f %s:p:r'],
        \     'tempfile': '{tempname()}.cpp',
        \   } : {},
        \ 'eruby': {
        \   'command': 'erb',
        \   'exec': '%c -T - %s %a',
        \ },
        \ 'go':
        \   $GOARCH ==# '386' ? {
        \     'exec':
        \       s:is_win() ?
        \         ['8g %s', '8l -o %s:p:r.exe %s:p:r.8', '%s:p:r.exe %a', 'del /F %s:p:r.exe'] :
        \         ['8g %s', '8l -o %s:p:r %s:p:r.8', '%s:p:r %a', 'rm -f %s:p:r']
        \   } :
        \   $GOARCH ==# 'amd64' ? {
        \     'exec': ['6g %s', '6l -o %s:p:r %s:p:r.6', '%s:p:r %a', 'rm -f %s:p:r'],
        \   } :
        \   $GOARCH ==# 'arm' ? {
        \     'exec': ['5g %s', '5l -o %s:p:r %s:p:r.5', '%s:p:r %a', 'rm -f %s:p:r'],
        \   } : {},
        \ 'groovy': {
        \   'exec': '%c -c {&fenc==""?&enc:&fenc} %s %a',
        \ },
        \ 'haskell': {
        \   'command': 'runghc',
        \   'tempfile': '{tempname()}.hs',
        \   'eval_template': 'main = print $ %s',
        \ },
        \ 'java': {
        \   'exec': ['javac %s', '%c %s:t:r %a', ':call delete("%S:t:r.class")'],
        \   'output_encode': '&tenc:&enc',
        \ },
        \ 'javascript': {
        \   'command': executable('js') ? 'js':
        \              executable('jrunscript') ? 'jrunscript':
        \              executable('cscript') ? 'cscript': '',
        \   'tempfile': '{tempname()}.js',
        \ },
        \ 'llvm': {
        \   'command': 'llvm-as %s -o=- | lli - %a',
        \ },
        \ 'lua': {},
        \ 'dosbatch': {
        \   'command': '',
        \   'exec': 'call %s %a',
        \   'tempfile': '{tempname()}.bat',
        \ },
        \ 'io': {},
        \ 'ocaml': {},
        \ 'perl': {
        \   'eval_template': join([
        \     'use Data::Dumper',
        \     '$Data::Dumper::Terse = 1',
        \     '$Data::Dumper::Indent = 0',
        \     'print Dumper eval{%s}'], ';')
        \ },
        \ 'python': {'eval_template': 'print(%s)'},
        \ 'php': {},
        \ 'r': {
        \   'command': 'R',
        \   'exec': '%c --no-save --slave %a < %s',
        \ },
        \ 'ruby': {'eval_template': " p proc {\n%s\n}.call"},
        \ 'scala': {
        \   'output_encode': '&tenc:&enc',
        \ },
        \ 'scheme': {
        \   'command': 'gosh',
        \   'exec': '%c %s:p %a',
        \   'eval_template': '(display (begin %s))',
        \ },
        \ 'sed': {},
        \ 'sh': {},
        \ 'vim': {
        \   'command': ':source',
        \   'exec': '%c %s',
        \   'eval_template': "echo %s",
        \ },
        \ 'zsh': {},
        \}
  lockvar! g:quickrun_default_config
endfunction

call s:init()

command! -nargs=* -range=% -complete=customlist,quickrun#complete QuickRun
\ call quickrun#run('-start <line1> -end <line2> ' . <q-args>)


nnoremap <silent> <Plug>(quickrun-op) :<C-u>set operatorfunc=QuickRun<CR>g@

silent! nnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode n<CR>
silent! vnoremap <silent> <Plug>(quickrun) :<C-u>QuickRun -mode v<CR>
" Default key mappings.
if !exists('g:quickrun_no_default_key_mappings')
\  || !g:quickrun_no_default_key_mappings
  silent! map <unique> <Leader>r <Plug>(quickrun)
endif

let &cpo = s:save_cpo
unlet s:save_cpo
