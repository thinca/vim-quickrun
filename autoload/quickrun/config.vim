" Converts a string as argline or a list of config to config object.
function quickrun#config#normalize(config) abort
  let t = type(a:config)
  if t is# v:t_string
    return s:from_arglist(s:parse_argline(a:config))
  elseif t is# v:t_list
    let config = {}
    for c in a:config
      call extend(config, quickrun#config#normalize(c))
    endfor
    return config
  elseif t is# v:t_dict
    return deepcopy(a:config)
  endif
  throw 'quickrun: Unsupported config type: ' . type(a:config)
endfunction

function quickrun#config#apply_recent_region(config) abort
  if !has_key(a:config, 'mode')
    let a:config.mode = histget(':') =~# "^'<,'>\\s*Q\\%[uickRun]" ? 'v' : 'n'
  endif
  if a:config.mode ==# 'v'
    let a:config.region = {
    \   'first': getpos("'<")[1 :],
    \   'last':  getpos("'>")[1 :],
    \   'wise': visualmode(),
    \ }
  endif
endfunction

function quickrun#config#build(type, ...) abort
  let config = a:0 ? a:1 : {}
  let type = {'type': a:type}
  for c in [
  \ 'b:quickrun_config',
  \ 'type',
  \ 'g:quickrun_config[config.type]',
  \ 'g:quickrun#default_config[config.type]',
  \ 'g:quickrun_config["_"]',
  \ 'g:quickrun_config["*"]',
  \ 'g:quickrun#default_config["_"]',
  \ ]
    if exists(c)
      let new_config = eval(c)
      if 0 <= stridx(c, 'config.type')
        let config_type = ''
        while has_key(config, 'type')
        \   && has_key(new_config, 'type')
        \   && config.type !=# ''
        \   && config.type !=# config_type
          let config_type = config.type
          call extend(config, new_config, 'keep')
          let config.type = new_config.type
          let new_config = exists(c) ? eval(c) : {}
        endwhile
      endif
      call extend(config, new_config, 'keep')
    endif
  endfor
  return config
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
        if type(config[option]) == type([])
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
      let option = arg[1:]
    elseif arg[0] ==# '>'
      if arg[1] ==# '>'
        let config.append = 1
        let arg = arg[1:]
      endif
      let config.outputter = arg[1:]
    elseif arg[0] ==# '<'
      let config.input = arg[1:]
    else
      let config.type = arg
    endif
  endfor
  return config
endfunction
