let s:suite = themis#suite('binary')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')
call themis#helper('command').with(s:)

function! s:suite.before_each()
  let g:git_appraise_binary = 0
endfunction

function! s:suite.check_binary_exists()
  let g:git_appraise_binary = "vim"
  call s:assert.equals(s:gitappraise.CheckBinary(), 1)
endfunction

function! s:suite.check_binary_doesnt_exist()
  let g:git_appraise_binary = ""
  Throws /git-appraise: git_appraise_binary not set/ :call gitappraise.CheckBinary()
endfunction

function! s:suite.check_binary_isnt_executable()
  let g:git_appraise_binary = ".gitignore"
  Throws /git-appraise: git_appraise_binary not executable/ :call gitappraise.CheckBinary()
endfunction
