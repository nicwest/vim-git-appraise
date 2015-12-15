let s:suite = themis#suite('list')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')
call themis#helper('command').with(s:)

let s:original_cwd = getcwd()
let s:test_git_path = ""

function! s:suite.before()
  let g:git_appraise_binary = exepath('git-appraise')
  let l:rand = system("echo $RANDOM")
  let l:path = "/tmp/vim-git-appraise-test." . l:rand
  call system("mkdir " . l:path)
  execute "cd" l:path
  call system("git init")
  call system("echo 'test text' > test.txt")
  call system("git add --all")
  call system("git commit -m 'first commit!'")
  call system("git checkout -b new-feature")
  call system("echo 'ALL I WANT IS CAKE!' > test.txt")
  call system("git add --all")
  call system("git commit -m 'NEW commit!'")
  call system(g:git_appraise_binary . " request")
  call system("git checkout master")
  call system("git checkout -b bug-fix")
  call system("echo 'I LIKE PIE!' > test.txt")
  call system("git add --all")
  call system("git commit -m 'fixing all dem bugs'")
  call system(g:git_appraise_binary . " request")
  call system(g:git_appraise_binary . " accept")
  execute "cd" s:original_cwd
  let s:test_git_path = l:path
endfunction

function! s:suite.after()
  call system("rm -rf /tmp/vim-git-appraise-test.*")
endfunction

function! s:suite.get_list()
  execute "cd" s:test_git_path
  let l:list = s:gitappraise.GetList()
  let l:item = l:list[0]
  call s:assert.match(l:item[0],'\[accepted\] [a-z0-9]\{12\}')
  call s:assert.equals(l:item[1],'fixing all dem bugs')
  let l:item = l:list[1]
  call s:assert.match(l:item[0],'\[pending\] [a-z0-9]\{12\}')
  call s:assert.equals(l:item[1],'NEW commit!')
endfunction
