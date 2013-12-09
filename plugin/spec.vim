" Get file path
let s:plugin_path = expand("<sfile>:p:h:h")

" Determine which command based on filetype
function! s:GetCorrectCommand()
  " Set default {rspec} command (ruby/rails)
  if &filetype ==? 'ruby'
    if !exists("g:rspec_command")
      let s:cmd = "rspec {spec}"
      call s:GUIRunning()
    else
      let g:spec_command = g:rspec_command
    endif
  " Set default {mocha} command (javascript)
  elseif &filetype ==? 'javascript'
    if !exists("g:mocha_js_command")
      let s:cmd = "mocha {spec}"
      call s:GUIRunning()
    else
      let g:spec_command = g:mocha_js_command
    endif
  " Set default {mocha} command (coffeescript)
  elseif &filetype ==? 'coffee'
    if !exists("g:mocha_coffee_command")
      let s:cmd = "mocha --compilers coffee:coffee-script {spec}"
      call s:GUIRunning()
    else
      let g:spec_command = g:mocha_coffee_command
    endif
  " Fallthrough default
  else
    let g:spec_command = ""
  endif
endfunction

" Run GUI version or Terminal version
function! s:GUIRunning()
  if has("gui_running") && has("gui_macvim")
    let g:spec_command = "silent !" . s:plugin_path . "/bin/run_in_os_x_terminal '" . s:cmd . "'"
  else
    let g:spec_command = "!echo " . s:cmd . " && " . s:cmd
  endif
endfunction

" Mocha Nearest Test
function! s:GetNearestTest()
  let callLine = line (".")           "cursor line
  let file = readfile(expand("%:p"))  "read current file
  let lineCount = 0                   "file line counter
  let lineDiff = 999                  "arbituary large number
  let descPattern='\v\_^\s*it\s*[(]*\s*[''"]{1}\zs[^''"]+\ze[''"]{1}'
  for line in file
    let lineCount += 1
    let match = match(line,descPattern)
    if(match != -1)
      let currentDiff = callLine - lineCount
      " break if closest test is the next test
      if(currentDiff < 0 && lineDiff != 999)
        break
      endif
      " if closer test is found, cache new nearest test
      if(currentDiff <= lineDiff)
        let lineDiff = currentDiff
        let s:nearestTest = matchstr(line,descPattern)
      endif
    endif
  endfor
endfunction

" All Specs
function! RunAllSpecs()
  if isdirectory('spec')
    let l:spec = "spec"
  else
    let l:spec = "test"
  endif
  call SetLastSpecCommand(l:spec)
  call RunSpecs(l:spec)
endfunction

" Current File
function! RunCurrentSpecFile()
  if InSpecFile()
    let l:spec = @%
    call SetLastSpecCommand(l:spec)
    call RunSpecs(l:spec)
  else
    call RunLastSpec()
  endif
endfunction

" Nearest Spec
function! RunNearestSpec()
  if InSpecFile()
    if &filetype ==? "ruby"
      let l:spec = @% . ":" . line(".")
    else
      call s:GetNearestTest()
      let l:spec = @% . " -g '" . s:nearestTest . "'"
    end
    call SetLastSpecCommand(l:spec)
    call RunSpecs(l:spec)
  else
    call RunLastSpec()
  endif
endfunction

" Last Spec
function! RunLastSpec()
  if exists("s:last_spec_command")
    call RunSpecs(s:last_spec_command)
  endif
endfunction

" Current Spec File Name
function! InSpecFile()
  if &filetype ==? "ruby"
    return match(expand("%"), "_spec.rb$") != -1 || match(expand("%"), ".feature$") != -1
  else
    return match(expand("%"), "^test/") != -1 || match(expand("%"), "^spec/") != -1
  end
endfunction

" Cache Last Spec Command
function! SetLastSpecCommand(spec)
  let s:last_spec_command = a:spec
endfunction

" Spec Runner
function! RunSpecs(spec)
  call s:GetCorrectCommand()
  if g:spec_command ==? ""
    echom "No spec command specified."
  else
    execute substitute(g:spec_command, "{spec}", a:spec, "g")
  end
endfunction
