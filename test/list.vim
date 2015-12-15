let s:suite = themis#suite('list')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:gitappraise = s:scope.funcs('autoload/gitappraise.vim')
call themis#helper('command').with(s:)

let s:original_cwd = getcwd()
let s:test_git_path = ""

function! s:suite.before()
  let g:git_appraise_binary = 'git-appraise'
  let l:rand = system("echo $RANDOM")
  let l:path = "/tmp/vim-git-appraise-test." . l:rand
  call themis#log(system("mkdir " . l:path))
  execute "cd" l:path
  call themis#log(system("git init"))
  call themis#log(system("echo 'test text' > test.txt"))
  call themis#log(system("git add --all"))
  call themis#log(system("git commit -m 'first commit!'"))
  call themis#log(system("git checkout -b new-feature"))
  call themis#log(system("echo 'ALL I WANT IS CAKE!' > test.txt"))
  call themis#log(system("git add --all"))
  call themis#log(system("git commit -m 'NEW commit!'"))
  call themis#log(system(g:git_appraise_binary . " request"))
  call themis#log(system("git checkout master"))
  call themis#log(system("git checkout -b bug-fix"))
  call themis#log(system("echo 'I LIKE PIE!' > test.txt"))
  call themis#log(system("git add --all"))
  call themis#log(system("git commit -m 'fixing all dem bugs'"))
  call themis#log(system(g:git_appraise_binary . " request"))
  call themis#log(system(g:git_appraise_binary . " accept"))
  execute "cd" s:original_cwd
  let s:test_git_path = l:path
endfunction

function! s:suite.after()
  call system("rm -rf /tmp/vim-git-appraise-test.*")
  execute "cd" s:original_cwd
endfunction

function! s:suite.get_list()
  execute "cd" s:test_git_path
  let l:list = s:gitappraise.GetList()
  let l:item = l:list[0]
  call s:assert.equals(l:item[0],'accepted')
  call s:assert.match(l:item[1],'[a-z0-9]\+')
  call s:assert.equals(l:item[2],'fixing all dem bugs')
  let l:item = l:list[1]
  call s:assert.equals(l:item[0],'pending')
  call s:assert.match(l:item[1], '[a-z0-9]\+')
  call s:assert.equals(l:item[2],'NEW commit!')
endfunction
