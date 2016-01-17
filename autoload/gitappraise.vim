" Vimscript Setup: {{{1
let s:save_cpo = &cpo
set cpo&vim

" Vital!
let s:V = vital#of('gitappraise')
let s:JSON = s:V.import('Web.JSON')

let s:BinaryOk = 0
let s:pwd = ""

" Private Functions: {{{1
" Utils: {{{2
function! s:CheckBinary() abort
  if executable(g:git_appraise_binary)
    return 1
  else
    if g:git_appraise_binary == ""
      throw "git-appraise: git_appraise_binary not set"
    endif
    throw "git-appraise: git_appraise_binary not executable"
  endif
endfunction

function! s:GetLineInDiff() abort
  let l:result = {'got_files': 0, 'done': 0, 'got_line': 0, 'new': 0, 'deleted': 0, 'files': {}}
  let l:buffer_line = line(".")
  let l:current_line = l:buffer_line
  let l:file_lines = {}
  while !l:result.done
    if l:current_line < 1
      let l:result.done = 0
    endif
    let l:line = getline(l:current_line)

    if !l:result.got_files && l:line !~ '^diff --git.*'
      let l:current_line = search('^diff --git.*', 'Wnbc', 0)
      continue
    endif

    if l:line =~ '^diff --git.*'
      let l:files = matchlist(l:line, '^diff --git \(.\)\/\(.*\) \(.\)\/\(.*\)$')
      let l:result.files[l:files[1]] = {'filename': l:files[2]}
      let l:result.files[l:files[3]] = {'filename': l:files[4]}

      let l:current_line += 1
      let l:line = getline(l:current_line)

      if l:line =~ '^new file mode'
        let l:current_line += 1
        let l:line = getline(l:current_line)
        let l:result.new = 1
      endif

      if l:line =~ '^deleted file mode'
        let l:current_line += 1
        let l:line = getline(l:current_line)
        let l:result.deleted = 1
      endif

      let l:hashes = matchlist(l:line, '^index \(.*\)\.\.\([^ ]\+\).*$')
      let l:result.files[l:files[1]].hash = l:hashes[1]
      let l:result.files[l:files[3]].hash = l:hashes[2]

      for l:file in keys(l:result.files)
        let l:current_line += 1
        let l:line = getline(l:current_line)
        for l:key in keys(l:result.files)
          if l:result.files[l:key].hash =~ '^0\+$'
            let l:line = substitute(l:line, '/dev/null', l:key . '//dev/null', 0)
          endif
        endfor
        let l:sign_file = matchlist(l:line, '^\(.\)\1\1 \(.\)\/.*')
        let l:result.files[l:sign_file[2]].sign = l:sign_file[1]
      endfor
      let l:result.got_files = 1
      if l:current_line < l:buffer_line
        let l:current_line = l:buffer_line
      else 
        let l:current_line +=1
      endif
      continue
    endif

    if l:result.got_files && !l:result.got_line && l:line !~ '^@@.*'
      let l:current_line = search('^@@.*', 'bnWc', l:current_line)
      continue
    endif

    if l:result.got_files && !l:result.got_line && l:line =~ '^@@.*'
      for l:key in keys(l:result.files)
        let l:r = l:result.files[l:key]
        let l:starting_line_no = matchlist(l:line, ' ' . l:r.sign . '\([0-9]\+\)')
        let l:file_lines[l:r.sign] = eval(l:starting_line_no[1])
        let l:result.files[l:key].lineno = eval(l:starting_line_no[1])
      endfor
      let l:result.got_line = 1
      let l:result.start_line = l:current_line
    endif

    if l:result.got_files && l:result.got_line 
      let l:current_line += 1
      let l:line = getline(l:current_line)
      let l:sign = l:line[0]
      if l:sign == ' '
        for l:key in keys(l:file_lines)
          let l:file_lines[l:key] +=1
        endfor
      else
        let l:file_lines[l:sign] +=1
      endif
    endif

    if l:result.got_files && l:result.got_line && l:current_line >= l:buffer_line
      for l:key in keys(l:result.files)
        let l:result.files[l:key].lineno = l:file_lines[l:result.files[l:key].sign]
      endfor
      let l:result.done = 1
    endif

  endwhile
  return l:result
endfunction

function! s:FindDiffLineForFile(filename, lineno, whatfile) abort
  let l:current_cursor = getpos('.')
  norm! gg^
  call search('diff --git .*/' . a:filename . ' .*', 'cW', 'cW')
  let l:result = s:GetLineInDiff()
  let l:current_line = l:result.start_line
  let l:done = 0
  let l:line_in_diff = 0
  let l:file_lines = {}
  for l:key in keys(l:result.files)
    let l:f = l:result.files[l:key]
    let l:file_lines[l:f.sign] = l:f.lineno
  endfor
  let l:file_sign = l:result.files[a:whatfile].sign
  while !l:done
    let l:line = getline(l:current_line)

    if l:line =~ '^@@.*'
      for l:key in keys(l:result.files)
        let l:r = l:result.files[l:key]
        let l:starting_line_no = matchlist(l:line, ' ' . l:r.sign . '\([0-9]\+\)')
        let l:file_lines[l:r.sign] = eval(l:starting_line_no[1])
        let l:result.files[l:key].lineno = eval(l:starting_line_no[1])
      endfor
      let l:result.got_line = 1
      let l:result.start_line = l:current_line
      let l:current_line += 1
      continue
    endif

    if l:line !~ '^@@.*'
      let l:current_line += 1
      let l:line = getline(l:current_line)
      let l:sign = l:line[0]
      if l:sign == ' '
        for l:key in keys(l:file_lines)
          let l:file_lines[l:key] +=1
        endfor
      else
        let l:file_lines[l:sign] +=1
      endif
    endif

    if l:file_lines[l:file_sign] == a:lineno
      let l:line_in_diff = l:current_line
      let l:done = 1
    endif
  endwhile
  call setpos('.', l:current_cursor)
  return l:line_in_diff
endfunc

function! s:SwapCwd() abort
  let s:pwd = getcwd()
  if bufname('%') !~ 'git-appraise://'
    lcd %:p:h
  endif
endfunction

function! s:UnSwapCwd() abort
  execute "lcd" s:pwd
  let s:pwd = ""
endfunction

" List: {{{2
function! s:ListSyntax() abort
  syntax clear
  syn keyword GitAppraisePending pending contained
  syn keyword GitAppraiseAccepted accepted contained
  syn keyword GitAppraiseRejected rejected contained

  syn match GitAppraiseHash /\s\+[a-z0-9]\+ / contained

  syn match GitAppraiseSummaryStatus /^\[[a-z]\+\]/ contained contains=GitAppraisePending,GitAppraiseAccepted,GitAppraiseRejected
  syn match GitAppraiseSummaryDetails /^\[[a-z]\+\]\s\+[a-z0-9]\+ / contained contains=GitAppraiseSummaryStatus,GitAppraiseHash
  syn match GitAppraiseSummaryLine '^\[[a-z]\+\]\s\+[a-z0-9]\+ .*$' contains=GitAppraiseSummaryDetails

  hi GitAppraiseSummaryStatus term=bold cterm=bold gui=bold 
  hi GitAppraisePending term=bold cterm=bold gui=bold ctermfg=11 guifg=#f0c674
  hi GitAppraiseAccepted term=bold cterm=bold gui=bold ctermfg=193 guifg=#d7ffaf
  hi GitAppraiseRejected term=bold cterm=bold gui=bold ctermfg=9 guifg=#cc6666
  hi GitAppraiseHash ctermfg=13 guifg=#b294bb
endfunction

function! s:ListRequestHash() abort
  let l:line = getline('.')
  let l:hash = matchlist(l:line, '^\s*\[.*\]\s\+\([a-z0-9]*\)')[1]
  return l:hash
endfunction

function! s:ListBinds() abort
  nnoremap <buffer> <silent> <space> :call gitappraise#show(<SID>ListRequestHash())<CR>
  nnoremap <buffer> <silent> <CR> :call gitappraise#show(<SID>ListRequestHash())<CR>
  nnoremap <buffer> <silent> q :call bw!<CR>
  nnoremap <buffer> <silent> <ESC> :call bw!<CR>
endfunction

function! s:ListBuffer(list) abort
  if !bufexists('git-appraise://list')
    badd git-appraise://list
  endif
  let l:summary_buffer = bufnr('git-appraise://list')
  call setbufvar(l:summary_buffer, '&bufhidden', 'hide')
  call setbufvar(l:summary_buffer, '&buflisted', 0)
  call setbufvar(l:summary_buffer, '&buftype', 'nofile')
  call setbufvar(l:summary_buffer, '&ft', 'gitappraise')
  execute 'silent keepa keepjump buffer' l:summary_buffer
  call setbufvar(l:summary_buffer, '&readonly', 0)
  silent norm! gg"_dG
  for l:item in a:list
    call append('$', '[' . l:item[0] . "]\t" . l:item[1] . ' ' . l:item[2])
  endfor
  silent norm! gg"_dd
  call setbufvar(l:summary_buffer, '&readonly', 1)
endfunction


function! s:SortList(i1, i2) abort
  return a:i1[0] == a:i2[0] ? 0 : a:i1[0] > a:i2[0] ? 1 : -1
endfunction

function! s:GetList() abort
  let l:cmd = g:git_appraise_binary . " list"
  let l:output = system(l:cmd)
  let l:list_raw = split(l:output, '\s*\n\s*')
  let l:list = []
  let l:current = []
  for l:item in l:list_raw[1:]
    if len(l:current) == 0
      let l:details = matchlist(l:item, '\[\([a-z]\+\)\] \([a-z0-9]\+\)') 
      call add(l:current, l:details[1])
      call add(l:current, l:details[2])
    else 
      call add(l:current, l:item)
      call add(l:list, l:current)
      let l:current = []
    endif
  endfor

  return sort(l:list, "s:SortList")
endfunction
" Show: {{{2

function! s:Show(hash) abort
  let l:cmd = g:git_appraise_binary . " show -json " . a:hash
  let l:output = system(l:cmd)
  if l:output =~ 'There is no matching review\..*'
    return {}
  endif
  let l:show = s:JSON.decode(l:output)
  return l:show
endfunction

function! s:ShowDiff(hash) abort
  let l:cmd = g:git_appraise_binary . " show -diff " . a:hash
  let l:output = system(l:cmd)
  return l:output
endfunction

function! s:ShowBinds() abort
  nnoremap <buffer> <silent> <space> :call <SID>ShowFileFromDiff()<CR>
  nnoremap <buffer> <silent> <CR> :call <SID>ShowFileFromDiff()<CR>
  nnoremap <buffer> <silent> q :call bw!<CR>
  nnoremap <buffer> <silent> <ESC> :call bw!<CR>
endfunction

function! s:ShowFileFromDiff() abort
  let l:current_line = s:GetLineInDiff()
  echo l:current_line
endfunction


function! s:ShowBuffer(diff) abort
  if !bufexists('git-appraise://show')
    badd git-appraise://show
  endif
  let l:summary_buffer = bufnr('git-appraise://show')
  call setbufvar(l:summary_buffer, '&bufhidden', 'hide')
  call setbufvar(l:summary_buffer, '&buflisted', 0)
  call setbufvar(l:summary_buffer, '&buftype', 'nofile')
  call setbufvar(l:summary_buffer, '&ft', 'diff')
  execute 'silent keepa keepjump buffer' l:summary_buffer
  call setbufvar(l:summary_buffer, '&readonly', 0)
  silent norm! gg"_dG
  let l:reg_contents = @b
  let @d = a:diff
  put d
  let @d = l:reg_contents
  silent norm! gg"_dd
  call setbufvar(l:summary_buffer, '&readonly', 1)
endfunction

" Comment: {{{2
" Accept: {{{2
" Reject: {{{2
" Push: {{{2
" Pull: {{{2

" Library Interface: {{{1
function! gitappraise#show(hash) abort
  call s:SwapCwd()
  let l:request = s:Show(a:hash)
  let l:diff = s:ShowDiff(a:hash)
  call s:ShowBuffer(l:diff)
  call s:ShowBinds()
  call s:UnSwapCwd()
endfunction

function! gitappraise#list() abort
  call s:SwapCwd()
  let l:list = s:GetList()
  call s:ListBuffer(l:list)
  call s:ListBinds()
  call s:ListSyntax()
  call s:UnSwapCwd()
endfunction

" Teardown:{{{1
let &cpo = s:save_cpo

" Misc: {{{1
" vim: set ft=vim ts=2 sw=2 tw=78 et fdm=marker:
