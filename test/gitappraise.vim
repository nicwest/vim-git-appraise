let s:suite = themis#suite('binary')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')

function! s:suite.check_binary_exists()
  let g:git_appraise_binary = "vim"
  call s:assert.equals(s:gitappraise.CheckBinary(), 1)
endfunction

function! s:suite.check_binary_doesnt_exist()
  let g:git_appraise_binary = "/asdlfklksadf/dome.sh"
  call s:assert.equals(s:gitappraise.CheckBinary(), 0)
endfunction

function! s:suite.check_binary_isnt_executable()
  let g:git_appraise_binary = "./gitappraise.vim"
  call s:assert.equals(s:gitappraise.CheckBinary(), 0)
endfunction
