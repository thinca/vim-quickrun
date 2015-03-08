" quickrun: hook/cd: Changes current directory.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:hook = {
\   'config': {
\     'directory': '',
\   },
\ }

function! s:hook.init(session) abort
  let self._cd = ''
  if self.config.directory ==# ''
    let self.config.enable = 0
  endif
endfunction

function! s:hook.on_ready(session, context) abort
  let self._cd = getcwd()
  let self._localdir = haslocaldir()
  let directory = a:session.build_command(self.config.directory)
  if self._localdir
    let self._id = {}
    let w:quickrun_hook_cd = self._id
    lcd `=directory`
  else
    cd `=directory`
  endif
  if self._cd ==# getcwd()
    " CD wasn't changed.
    let self._cd = ''
  endif
endfunction

function! s:hook.sweep() abort
  if self._cd ==# ''
    return
  endif
  if self._localdir
    if exists('w:quickrun_hook_cd') && w:quickrun_hook_cd is self._id
      unlet w:quickrun_hook_cd
      lcd `=self._cd`
    else
      for tabnr in range(1, tabpagenr('$'))
        for winnr in range(1, tabpagewinnr(tabnr, '$'))
          let w = gettabwinvar(tabnr, winnr, '')
          if get(w, 'quickrun_hook_cd') is self._id
            let [curtab, curwin] = [tabpagenr(), winnr()]
            let lz = &lazyredraw
            set lazyredraw
            try
              call s:move_tabwin(tabnr, winnr)
              unlet w:quickrun_hook_cd
              lcd `=self._cd`
              call s:move_tabwin(curtab, curwin)
            finally
              let &lazyredraw = lz
            endtry
            return
          endif
        endfor
      endfor
    endif
    " Couldn't restore... notify?
  else
    cd `=self._cd`
  endif
endfunction

function! s:move_tabwin(tab, win) abort
  execute 'tabnext' a:tab
  execute a:win 'wincmd w'
endfunction

function! quickrun#hook#cd#new() abort
  return deepcopy(s:hook)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
