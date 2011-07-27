" quickrun: runner: remote
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:is_win = has('win32') || has('win64')
let s:runner = {
\   'config': {
\     'vimproc': 0,
\   }
\ }

function! s:runner.validate()
  if !has('clientserver') || v:servername ==# ''
    throw 'Needs +clientserver feature.'
  endif
  if !s:is_win && !executable('sh')
    throw 'Needs "sh" on other than MS Windows.  Sorry.'
  endif
endfunction

function! s:runner.run(commands, input, session)
  let selfvim = s:is_win ? 'vim.exe' :
  \             !empty($_) ? $_ : v:progname

  let key = a:session.continue()
  let outfile = tempname()
  let a:session._temp_result = outfile
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
    let inputfile = tempname()
    let a:session._temp_input = inputfile
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
  call map(scriptbody, 'g:quickrun#V.iconv(v:val, &encoding, &termencoding)')
  let a:session._temp_script = script
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
        silent! execute '!start /b' script
      else
        silent! execute '!start /min' script
      endif

    else  "if executable('sh')  " Simpler shell.
      silent! execute '!sh' script '&'
    endif
  endif
endfunction

function! s:conv_vim2remote(runner, selfvim, cmd)
  if a:cmd !~# '^\s*:'
    return a:cmd
  endif
  return s:make_command(a:runner, [a:selfvim,
  \       '--servername', v:servername, '--remote-expr',
  \       printf('quickrun#execute(%s)', string(a:cmd))])
endfunction

function! s:make_command(runner, args)
  return join([shellescape(a:args[0])] +
  \           map(a:args[1 :], 'a:runner.shellescape(v:val)'), ' ')
endfunction


function! quickrun#runner#remote#new()
  return deepcopy(s:runner)
endfunction

let &cpo = s:save_cpo
