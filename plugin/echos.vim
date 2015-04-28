if expand('<sfile>:p')!=#expand('%:p') && exists('g:loaded_echos')| finish| endif| let g:loaded_echos = 1
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let g:echos_enable_visible_str = get(g:, 'echos_enable_visible_str', 0)

command! -nargs=+ -complete=expression -bang   Echos  let s:ret = '' | for s:arg in echos#parse_args(<q-args>)
  \ | let s:ret .= echos#stringify(eval(s:arg), <bang>g:echos_enable_visible_str) | endfor | echom s:ret | unlet s:ret s:arg

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
