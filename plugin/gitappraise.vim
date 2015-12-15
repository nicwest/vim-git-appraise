" Vimscript Setup: {{{1
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development.
"if exists("g:loaded_git_appraise")
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_git_appraise = 1

" Options: {{{1
if !exists('g:git_appraise_bin')
  if executable('git-appraise')
    let g:git_appraise_bin = 'git-appraise'
  else
    let g:git_appraise_bin = ""
  endif

endif

" Commands: {{{1
command! -nargs=0 GARequest call gitappraise#request()
command! -nargs=? GAPush call gitappraise#push()
command! -nargs=? GAPull call gitappraise#pull()
command! -nargs=0 GAList call gitappraise#list()
command! -nargs=1 GAShow call gitappraise#show()
command! -nargs=1 GAComment call gitappraise#comment()
command! -nargs=* GAAccept call gitappraise#accept()
command! -nargs=0 -bang GASubmit call gitappraise#submit(<bang> == "!")


" Teardown: {{{1
let &cpo = s:save_cpo

" Misc: {{{1
" vim: set ft=vim ts=2 sw=2 tw=78 et fdm=marker:
