" s:sid([{SNR} [, {varname} [, {funcname}]]])
" Usage:
" execute V.Vim.sid()
" let sfunc = function(sid . 'funcname')
function! s:sid(...)
  let snr      = 1 <= a:0 && a:1
  let varname  = 2 <= a:0 ? a:2 : 's:sid'
  let funcname = 3 <= a:0 ? a:3 : 'sid'
  let funcname = 's:' . funcname
  let pat = snr ? '\zs<SNR>\d\+_\ze' : '<SNR>\zs\d\+\ze_'
  let pat .= funcname . '$'
  " \ '  return matchstr(expand("<sfile>"), ' . string(pat) . ')',
  " \ 'delfunction ' . funcname,
  return join([
  \ 'function ' . funcname . '()',
  \ '  return "foo"',
  \ 'endfunction', '',
  \ 'let ' . varname . ' = ' . funcname . '()',
  \ ], "\n")
endfunction
