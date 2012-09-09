" quickrun: outputter/buffer: Outputs to a vim buffer.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

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

function! s:outputter.init(session)
  let self._append = self.config.append
  let self._line = 0
  let self._source_bufnr = bufnr('%')
endfunction

function! s:outputter.start(session)
  call s:open_result_window(self.config)
  if !self._append
    silent % delete _
  endif
  call s:set_running_mark(self.config.running_mark)
  execute bufwinnr(self._source_bufnr) 'wincmd w'
endfunction

function! s:outputter.output(data, session)
  call s:open_result_window(self.config)
  if self._line == 0
    let self._line = line('$')
  endif
  let oneline = line('$') == 1
  let data = getline('$') . a:data
  silent $ delete _
  if data =~# '\n$'
    " :put command do not insert the last line.
    let data .= "\n"
  endif

  " XXX 'fileformat' of a new buffer depends on 'fileformats'.
  if &l:fileformat ==# 'dos'
    let data = substitute(data, "\r\n", "\n", 'g')
  endif

  silent $ put = data
  if oneline
    silent 1 delete _
  endif
  call s:set_running_mark(self.config.running_mark)
  execute bufwinnr(self._source_bufnr) 'wincmd w'
  redraw
endfunction

function! s:outputter.finish(session)

  call s:open_result_window(self.config)
  execute self._line
  silent normal! zt
  let is_closed = 0
  if self.config.close_on_empty
    if line('$') == 1 && getline(1) =~ '^\s*$'
      quit
      let is_closed = 1
    endif
  endif
  if !is_closed && !self.config.into
    execute bufwinnr(self._source_bufnr) 'wincmd w'
  endif
  redraw
  if is_closed
      echohl MoreMsg
      echom "[QuickRun] Empty Output"
      echohl NONE
  endif
endfunction


function! s:open_result_window(config)
  let sp = a:config.split
  let sname = s:escape_file_pattern(a:config.name)
  if !bufexists(a:config.name)
    execute sp 'split'
    edit `=a:config.name`
    nnoremap <buffer> q <C-w>c
    setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
  elseif bufwinnr(sname) != -1
    execute bufwinnr(sname) 'wincmd w'
  else
    execute sp 'split'
    execute 'buffer' bufnr(sname)
  endif
  if &l:filetype !=# a:config.filetype
    let &l:filetype = a:config.filetype
  endif
  if exists('b:quickrun_running_mark')
    silent undo
    unlet b:quickrun_running_mark
  endif
endfunction

function! s:set_running_mark(mark)
  if a:mark !=# '' && !exists('b:quickrun_running_mark')
    let &undolevels = &undolevels  " split the undo block
    silent $ put =a:mark
    let b:quickrun_running_mark = 1
  endif
endfunction

function! s:escape_file_pattern(pat)
  return join(map(split(a:pat, '\zs'), '"[".v:val."]"'), '')
endfunction


function! quickrun#outputter#buffer#new()
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
