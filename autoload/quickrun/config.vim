" Converts a string as argline or a list of config to config object.
function quickrun#config#normalize(config) abort
  let t = type(a:config)
  if t is# v:t_string
    return quickrun#command#parse(a:config)
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
