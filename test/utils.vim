let s:suite = themis#suite('utils')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')
call themis#helper('command').with(s:)

function! s:suite.before()
  let g:git_appraise_binary = 'git-appraise'
endfunction

function! s:suite.swap_cwd()
  let l:pwd = getcwd()
  call s:gitappraise.SwapCwd()
  call s:assert.equals(getcwd(), expand("%:p:h"))
  call s:gitappraise.UnSwapCwd()
  call s:assert.equals(getcwd(), l:pwd)
endfunction
