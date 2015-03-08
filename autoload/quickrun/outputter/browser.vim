" quickrun: outputter/browser: Outputs to a web browser.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:default_name = tempname() . '.html'

let s:outputter = quickrun#outputter#file#new()

let s:outputter.init_file = s:outputter.init

function! s:outputter.validate() abort
  call openbrowser#load()
  if !exists('*openbrowser#open')
    throw 'Needs open-browser.vim.'
  endif
endfunction

function! s:outputter.init(session) abort
  if self.config.name ==# ''
    let self.config.name = s:default_name
  endif
  call self.init_file(a:session)
endfunction

function! s:outputter.finish(session) abort
  let saved = g:openbrowser_open_filepath_in_vim
  try
    let g:openbrowser_open_filepath_in_vim = 0
    call openbrowser#open(self._file)
  finally
    let g:openbrowser_open_filepath_in_vim = saved
  endtry
endfunction


function! quickrun#outputter#browser#new() abort
  return deepcopy(s:outputter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
