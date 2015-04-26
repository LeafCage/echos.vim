if expand('<sfile>:p')!=#expand('%:p') && exists('g:loaded_echos')| finish| endif| let g:loaded_echos = 1
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
command! -nargs=+ -complete=expression -bang   Echos  let s:ret = '' | for s:arg in echos#parse_args(<q-args>)
  \ | let s:ret .= echos#stringify(eval(s:arg), <bang>0) | endfor | echom s:ret | unlet s:ret s:arg

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
