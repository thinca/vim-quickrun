" quickrun: runner: python
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:python_loaded = 0
if has('python')
  try
python <<EOM
import vim, threading, subprocess, re, time

class QuickRun(threading.Thread):
    def __init__(self, cmds, key, input):
        threading.Thread.__init__(self)
        self.cmds = cmds
        self.key = key
        if not input:
          input = ''
        self.input = input

    def run(self):
        ret = 0
        try:
            for cmd in self.cmds:
                ret = self.execute(cmd)
                if ret != 0:
                    break
        except:
            pass
        finally:
            vim.eval("quickrun#session(%s, 'finish', %s)" % (self.key, ret))

    def execute(self, cmd):
        if re.match('^\s*:', cmd):
            vim.eval("quickrun#session(%s, 'output', quickrun#execute(%s))" %
                (self.key, self.vimstr(cmd)))
            return 0

        p = subprocess.Popen(cmd,
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT,
                             shell=True)
        p.stdin.write(self.input)
        p.stdin.close()
        self.set_nonblocking(p.stdout)
        while p.poll() == None:
            self.output(p.stdout)
            time.sleep(0.1)
        self.output(p.stdout)
        p.wait()
        return p.returncode

    def output(self, fp):
        try:
            data = fp.read()
            vim.eval("quickrun#session(%s, 'output', %s)" %
              (self.key, self.vimstr(data)))
        except:
            pass

    def vimstr(self, s):
        return "'" + s.replace("'", "''") + "'"

    def set_nonblocking(self, fh):
        import fcntl, os

        fd = fh.fileno()
        fl = fcntl.fcntl(fd, fcntl.F_GETFL)
        fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
EOM
  let s:python_loaded = 1
  catch
    " XXX: This method make debugging to difficult.
  endtry
endif


let s:runner = {}

function! s:runner.validate()
  if !has('python')
    throw 'Needs +python feature.'
  elseif !s:python_loaded
    throw 'Loading python code failed.'
  endif
endfunction

function! s:runner.run(commands, input, session)
  let key = string(a:session.continue())
  python QuickRun(vim.eval('a:commands'),
  \               vim.eval('key'),
  \               vim.eval('a:input')).start()
endfunction


function! quickrun#runner#python#new()
  return deepcopy(s:runner)
endfunction


let &cpo = s:save_cpo
