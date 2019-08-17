let s:V = g:quickrun#V


function quickrun#command#execute(config, use_range, line1, line2) abort
  try
    let config = {}
    if a:use_range
      let config.region = {
      \   'first': [a:line1, 0, 0],
      \   'last':  [a:line2, 0, 0],
      \   'wise': 'V',
      \ }
    endif
    call quickrun#run([config, a:config])
  catch /^quickrun:/
    call s:V.Vim.Message.error(v:exception)
  endtry
endfunction

function quickrun#command#complete(lead, cmd, pos) abort
  let line = split(a:cmd[: a:pos - 1], '', 1)
  let head = line[-1]
  let kinds = quickrun#module#get_kinds()
  if 2 <= len(line) && line[-2] =~# '^-'
    " a value of option.
    let opt = line[-2][1 :]
    if opt !=# 'type'
      let list = []
      if opt ==# 'mode'
        let list = ['n', 'v']
      elseif 0 <= index(kinds, opt)
        let list = map(filter(quickrun#module#get(opt),
        \                     'v:val.available()'), 'v:val.name')
      endif
      return filter(list, 'v:val =~# "^" . a:lead')
    endif

  elseif head =~# '^-'
    " a name of option.
    let list = ['type', 'src', 'srcfile', 'input', 'runner', 'outputter',
    \ 'command', 'exec', 'cmdopt', 'args', 'tempfile', 'mode']
    let mod_options = {}
    for kind in kinds
      for module in filter(quickrun#module#get(kind), 'v:val.available()')
        for opt in keys(module.config)
          let mod_options[opt] = 1
          let mod_options[kind . '/' . opt] = 1
          let mod_options[module.name . '/' . opt] = 1
          let mod_options[kind . '/' . module.name . '/' . opt] = 1
        endfor
      endfor
    endfor
    let list += keys(mod_options)
    call map(list, '"-" . v:val')

  endif
  if !exists('list')
    " no context: types
    let list = keys(extend(exists('g:quickrun_config') ?
    \               copy(g:quickrun_config) : {}, g:quickrun#default_config))
    call filter(list, 'v:val !~# "^[_*]$"')
  endif

  let re = '^\V' . escape(head, '\') . '\v[^/]*/?'
  return uniq(sort(map(list, 'matchstr(v:val, re)')))
endfunction

function quickrun#command#parse(argline) abort
  return s:from_arglist(s:parse_argline(a:argline))
endfunction

" foo 'bar buz' "hoge \"huga"
" => ['foo', 'bar buz', 'hoge "huga']
" TODO: More improve.
" ex:
" foo ba'r b'uz "hoge \nhuga"
" => ['foo, 'bar buz', "hoge \nhuga"]
function s:parse_argline(argline) abort
  let argline = a:argline
  let arglist = []
  while argline !~# '^\s*$'
    let argline = matchstr(argline, '^\s*\zs.*$')
    if argline[0] =~# '[''"]'
      let arg = matchstr(argline, '\v([''"])\zs.{-}\ze\\@<!\1')
      let argline = argline[strlen(arg) + 2 :]
    else
      let arg = matchstr(argline, '\S\+')
      let argline = argline[strlen(arg) :]
    endif
    let arg = substitute(arg, '\\\(.\)', '\1', 'g')
    call add(arglist, arg)
  endwhile

  return arglist
endfunction

function s:from_arglist(arglist) abort
  let config = {}
  let option = ''
  for arg in a:arglist
    if option !=# ''
      if has_key(config, option)
        if type(config[option]) == v:t_list
          call add(config[option], arg)
        else
          let newarg = [config[option], arg]
          unlet config[option]
          let config[option] = newarg
        endif
      else
        let config[option] = arg
      endif
      let option = ''
    elseif arg[0] ==# '-'
      let option = arg[1 :]
    elseif arg[0] ==# '>'
      if arg[1] ==# '>'
        let config.append = 1
        let arg = arg[1 :]
      endif
      let config.outputter = arg[1 :]
    elseif arg[0] ==# '<'
      let config.input = arg[1 :]
    else
      let config.type = arg
    endif
  endfor
  return config
endfunction
