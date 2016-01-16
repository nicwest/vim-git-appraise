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
      let l:current_line -= 1
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
      let l:current_line -= 1
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


  call s:ShowBinds()