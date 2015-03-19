if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
scriptencoding utf-8
"=============================================================================
let s:TYPES = {"'": 'sqstr', '"': 'dqstr', '[': 'list', '{': 'dict', '(': 'paren'}
let s:OPERATORS = '\%([-+.*/%?:]\|\<is\%(not\)\?\>\|[=!][=~][#?]\?\|[<>]=\?[#?]\?\|&&\|||\)'
let s:OPERATORS_H = '^'. s:OPERATORS
let s:OPERATORS_L = s:OPERATORS. '$'
unlet s:OPERATORS

"Misc:
let s:Parser = {}
function! s:newParser(argsstr) "{{{
  let obj = copy(s:Parser)
  let obj.lumps = []
  let obj.argsstr = a:argsstr
  let obj.argslen = len(a:argsstr)
  let obj.i = match(a:argsstr, '\S')
  return obj
endfunction
"}}}
function! s:Parser.is_continue() "{{{
  return self.i!=-1
endfunction
"}}}
function! s:Parser.parse() "{{{
  let lump = self._get_lump()
  while self.i != -1
    if lump =~# s:OPERATORS_L
      let lump .= self._get_lump()
      continue
    end
    let operatorend = matchend(self.argsstr, s:OPERATORS_H, self.i)
    if operatorend==-1
      break
    end
    let i = match(self.argsstr, '\S', operatorend)
    if i==-1
      echoerr 'invalid opperator "'. self.argsstr[self.i :]. '"'
      break
    end
    let lump .= self.argsstr[self.i : operatorend-1]
    let self.i = i
    let lump .= self._get_lump()
  endwhile
  call add(self.lumps, lump)
endfunction
"}}}
function! s:Parser.get_result() "{{{
  return self.lumps
endfunction
"}}}
function! s:Parser._get_lump() "{{{
  let lasti = self._get_lumplasti()
  let lump = self.argsstr[self.i : lasti]
  let self.i = match(self.argsstr, '\S', lasti+1)
  return lump
endfunction
"}}}
function! s:Parser._get_lumplasti() "{{{
  return self['_lumplasti_of_'. get(s:TYPES, self.argsstr[self.i], 'eval')]()
endfunction
"}}}
function! s:Parser._get_dqstrpair_i(bgni) "{{{
  return match(self.argsstr, '\%([^\\]\\\)\@<!"', a:bgni+1)
endfunction
"}}}
function! s:Parser._get_sqstrpair_i(bgni) "{{{
  let i = match(self.argsstr, "'", a:bgni+1)
  while i!=-1 && self.argsstr[i+1] == "'"
    let i += 2
    let i = match(self.argsstr, "'", i)
  endwhile
  return i
endfunction
"}}}
function! s:Parser._get_nest_lasti(list, bgni) "{{{
  let lv = 1
  let i = a:bgni
  while lv
    let i = match(self.argsstr, '[' . a:list[2]. a:list[1]. '''"]', i+1)
    if i==-1
      throw 'incomplete '. a:list[0]. ' '. self.argsstr[self.i:]
    end
    let c = self.argsstr[i]
    if c == "'"
      let i = self._get_sqstrpair_i(i)
    elseif c == '"'
      let i = self._get_dqstrpair_i(i)
    elseif c == a:list[1]
      let lv += 1
    elseif c == a:list[2]
      let lv -= 1
    end
    if i==-1
      throw 'incomplete '. a:list[0]. ' '. self.argsstr[self.i:]
    end
  endwhile
  return i
endfunction
"}}}
function! s:Parser._lumplasti_of_dqstr() "{{{
  return self._get_dqstrpair_i(self.i)
endfunction
"}}}
function! s:Parser._lumplasti_of_sqstr() "{{{
  return self._get_sqstrpair_i(self.i)
endfunction
"}}}
function! s:Parser._lumplasti_of_list() "{{{
  return self._get_nest_lasti(['list', '[', ']'], self.i)
endfunction
"}}}
function! s:Parser._lumplasti_of_dict() "{{{
  return self._get_nest_lasti(['dictionary', '{', '}'], self.i)
endfunction
"}}}
function! s:Parser._lumplasti_of_paren() "{{{
  return self._get_nest_lasti(['parentheses', '(', ')'], self.i)
endfunction
"}}}
function! s:Parser._lumplasti_of_eval() "{{{
  let funcbgn_stopi = matchend(self.argsstr, '^\%([sg]:\)\?[[:alnum:]#]\+(', self.i)
  if funcbgn_stopi!=-1
    return self._lumplasti_of_function(funcbgn_stopi-1)
  end
  let stop = match(self.argsstr, '[[:blank:]''"]', self.i+1)
  return stop==-1 ? self.argslen-1 : stop-1
endfunction
"}}}
function! s:Parser._lumplasti_of_function(funcbgn_i) "{{{
  return self._get_nest_lasti(['function', '(', ')'], a:funcbgn_i)
endfunction
"}}}


"=============================================================================
"Main:
function! echos#parse_args(argsstr) "{{{
  let parser = s:newParser(a:argsstr)
  while parser.is_continue()
    call parser.parse()
  endwhile
  return parser.get_result()
endfunction
"}}}

let s:TYPE_STR = type('')
function! echos#stringify(val) "{{{
  return (type(a:val)==s:TYPE_STR ? a:val : string(a:val)). ' '
endfunction
"}}}


"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
