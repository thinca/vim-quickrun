" quickrun: outputter/multi: Meta outputter; Outputs to multiple outputters.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:outputter = {
\   'config': {
\     'targets': [],
\   },
\ }

function s:outputter.init(session) abort
  let self._outputters =
  \   map(self.config.targets, 'a:session.make_module("outputter", v:val)')
endfunction

function s:outputter.start(session) abort
  for outputter in self._outputters
    call outputter.start(a:session)
  endfor
endfunction

function s:outputter.output(data, session) abort
  for outputter in self._outputters
    call outputter.output(a:data, a:session)
  endfor
endfunction

function s:outputter.finish(session) abort
  for outputter in self._outputters
    call outputter.finish(a:session)
  endfor
endfunction


function quickrun#outputter#multi#new() abort
  return deepcopy(s:outputter)
endfunction
