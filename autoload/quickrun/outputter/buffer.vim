" quickrun: outputter/buffer: Outputs to a vim buffer.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:VT = g:quickrun#V.import('Vim.ViewTracer')

let s:outputter = {
\   'config': {
\     'name': '[quickrun output]',
\     'filetype': 'quickrun',
\     'append': 0,
\     'split': '%{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}',
\     'into': 0,
\     'running_mark': ':-)',
\     'close_on_empty': 0,
\   }
\ }

function! s:outputter.init(session) abort
  let self._append = self.config.append
  let self._line = 0
  let self._crlf = 0
  let self._lf = 0
endfunction

function! s:outputter.start(session) abort
  let prev_window = s:VT.trace_window()
  call s:open_result_window(self.config, a:session)
  if !self._append
    silent % delete _
    setlocal fileformat=unix
  endif
  call s:set_running_mark(self.config.running_mark)
  call s:VT.jump(prev_window)
endfunction

function! s:outputter.output(data, session) abort
  let prev_window = s:VT.trace_window()
  call s:open_result_window(self.config, a:session)

  let oneline = line('$') == 1
  let data = getline('$') . a:data
  silent $ delete _

  if self._line == 0
    let self._line = line('$') + (oneline ? 0 : 1)
    if 2 <= self._line
      let self._crlf = &l:fileformat ==# 'dos' || search("\r$", 'wn')
      let self._lf = &l:fileformat ==# 'unix' && search("[^\r]$", 'wn')
    endif
  endif

  let self._crlf = self._crlf || a:data =~# "\r\n"
  let self._lf = self._lf || a:data =~# "[^\r]\n"

  call s:normalize_fileformat(self._crlf, self._lf)

  if &l:fileformat ==# 'dos'
    let data = substitute(data, "\r\n", "\n", 'g')
  endif

  if data =~# '\n$'
    " :put command do not insert the last line.
    let data .= "\n"
  endif
  silent $ put = data
  if oneline
    silent 1 delete _
  endif

  call s:set_running_mark(self.config.running_mark)
  call s:VT.jump(prev_window)
  redraw
endfunction

function! s:outputter.finish(session) abort
  let prev_window = s:VT.trace_window()
  call s:open_result_window(self.config, a:session)
  execute self._line
  silent normal! zt
  let closed = self.config.close_on_empty && s:is_empty_buffer()
  if closed
    close
  endif
  if closed || !self.config.into
    call s:VT.jump(prev_window)
  endif
  redraw
  if closed
    echohl MoreMsg
    echomsg 'quickrun: outputter/buffer: Empty output.'
    echohl NONE
  endif
endfunction


function! s:open_result_window(config, session) abort
  let sp = a:config.split
  let sname = s:escape_file_pattern(a:config.name)
  let opened = 0
  if !bufexists(a:config.name)
    execute sp 'split'
    edit `=a:config.name`
    nnoremap <buffer> q <C-w>c
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
    setlocal fileformat=unix
    let opened = 1
  elseif bufwinnr(sname) != -1
    execute bufwinnr(sname) 'wincmd w'
  else
    execute sp 'split'
    execute 'buffer' bufnr(sname)
    let opened = 1
  endif
  if opened
    call a:session.invoke_hook('outputter_buffer_opened')
  endif
  if &l:filetype !=# a:config.filetype
    let &l:filetype = a:config.filetype
  endif
  if exists('b:quickrun_running_mark')
    silent undo
    unlet b:quickrun_running_mark
  endif
endfunction

function! s:normalize_fileformat(crlf, lf) abort
  " XXX Do not care `fileformat=mac`
  if &l:fileformat ==# 'unix' && a:crlf && !a:lf
    setlocal fileformat=dos
  elseif &l:fileformat ==# 'dos' && a:lf
    setlocal fileformat=unix
    for lnum in range(1, line('$'))
      call setline(lnum, getline(lnum) . "\r")
    endfor
  endif
endfunction

function! s:set_running_mark(mark) abort
  if a:mark !=# '' && !exists('b:quickrun_running_mark')
    let &undolevels = &undolevels  " split the undo block
    silent $ put =a:mark
    let b:quickrun_running_mark = 1
  endif
endfunction

function! s:is_empty_buffer() abort
  return line('$') == 1 && getline(1) =~# '^\s*$'
endfunction

function! s:escape_file_pattern(pat) abort
  return join(map(split(a:pat, '\zs'), '"[" . v:val . "]"'), '')
endfunction


function! quickrun#outputter#buffer#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
