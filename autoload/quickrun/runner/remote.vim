" quickrun: runner/remote: Runs in background by +clientserver feature.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim


let s:is_win = has('win32') || has('win64')
let s:runner = {
\   'config': {
\     'vimproc': 0,
\   }
\ }

function! s:runner.validate() abort
  if !has('clientserver') || v:servername ==# ''
    throw 'Needs +clientserver feature.'
  endif
  if !s:is_win && !executable('sh')
    throw 'Needs "sh" on other than MS Windows.  Sorry.'
  endif
endfunction

function! s:runner.run(commands, input, session) abort
  let selfvim = s:is_win ? 'vim.exe' :
  \             !empty($_) ? $_ : v:progname

  let key = a:session.continue()
  let outfile = a:session.tempname()
  let readfile = printf('join(readfile(%s, 1), "\n")', string(outfile))
  let expr = printf('quickrun#session(%s, "output", %s) + ' .
  \                 'quickrun#session(%s, "finish")',
  \                 string(key), readfile, string(key))
  let cmds = a:commands
  let callback = s:make_command(self,
  \        [selfvim, '--servername', v:servername, '--remote-expr', expr])

  call map(cmds, 's:conv_vim2remote(self, selfvim, v:val)')

  let in = a:input
  if in !=# ''
    let inputfile = a:session.tempname()
    call writefile(split(in, "\n", 1), inputfile, 'b')
    let in = ' <' . self.shellescape(inputfile)
  endif

  " Execute by script file to unify the environment.
  let script = tempname()
  let scriptbody = [
  \   printf('(%s)%s >%s 2>&1', join(cmds, '&&'), in, self.shellescape(outfile)),
  \   callback,
  \ ]
  if s:is_win
    let script .= '.bat'
    call insert(scriptbody, '@echo off')
    call map(scriptbody, 'v:val . "\r"')
  endif
  call map(scriptbody, 'g:quickrun#V.Process.iconv(v:val, &encoding, &termencoding)')
  call a:session.tempname(script)
  call writefile(scriptbody, script, 'b')

  let available_vimproc = globpath(&runtimepath, 'autoload/vimproc.vim') !=# ''
  if available_vimproc && self.config.vimproc
    if s:is_win
      let a:session._vimproc = vimproc#popen2(['cmd.exe', '/C', script])
    else
      let a:session._vimproc = vimproc#popen2(['sh', script])
    endif
  else
    if s:is_win
      if 703 <= v:version && has('patch203')
      \ || 703 < v:version
        silent! execute '!start /b' script
      else
        silent! execute '!start /min' script
      endif

    else  "if executable('sh')  " Simpler shell.
      silent! execute '!sh' script '&'
    endif
  endif
endfunction

function! s:conv_vim2remote(runner, selfvim, cmd) abort
  if a:cmd !~# '^\s*:'
    return a:cmd
  endif
  return s:make_command(a:runner, [a:selfvim,
  \       '--servername', v:servername, '--remote-expr',
  \       printf('quickrun#execute(%s)', string(a:cmd))])
endfunction

function! s:make_command(runner, args) abort
  return join([shellescape(a:args[0])] +
  \           map(a:args[1 :], 's:shellescape(v:val)'), ' ')
endfunction

function! s:shellescape(str) abort
  if s:is_cmd_exe()
    return '^"' . substitute(substitute(substitute(a:str,
    \             '[&|<>()^"%]', '^\0', 'g'),
    \             '\\\+\ze"', '\=repeat(submatch(0), 2)', 'g'),
    \             '\^"', '\\\0', 'g') . '^"'
  endif
  return shellescape(a:str)
endfunction

function! s:is_cmd_exe() abort
  return &shell =~? 'cmd\.exe'
endfunction


function! quickrun#runner#remote#new() abort
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
