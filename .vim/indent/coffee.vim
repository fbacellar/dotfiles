" Language:    CoffeeScript
" Maintainer:  Mick Koch <kchmck@gmail.com>
" URL:         http://github.com/kchmck/vim-coffee-script
" License:     WTFPL

if exists("b:did_indent")
  finish
endif

let b:did_indent = 1

setlocal autoindent
setlocal indentexpr=GetCoffeeIndent(v:lnum)
" Make sure GetCoffeeIndent is run when these are typed so they can be
" indented or outdented.
setlocal indentkeys+=0],0),0.,=else,=when,=catch,=finally

" Only define the function once.
if exists("*GetCoffeeIndent")
  finish
endif

" Keywords and operators to indent after
let s:INDENT_AFTER = '^\%(if\|unless\|else\|for\|while\|until\|'
\                  . 'loop\|switch\|when\|try\|catch\|finally\|'
\                  . 'class\)\>'
\                  . '\|'
\                  . '\%([([{:=]\|[-=]>\)$'

" Keywords and operators that continue a line
let s:CONTINUATION = '\<\%(is\|isnt\|and\|or\)\>$'
\                  . '\|'
\                  . '\%(-\@<!-\|+\@<!+\|<\|[-=]\@<!>\|\*\|/\|%\||\|'
\                  . '&\|,\|\.\@<!\.\)$'

" Operators that block continuation indenting
let s:CONTINUATION_BLOCK = '[([{:=]$'

" A continuation dot access
let s:DOT_ACCESS = '^\.'

" Keywords to outdent after
let s:OUTDENT_AFTER = '^\%(return\|break\|continue\|throw\)\>'

" A compound assignment like `... = if ...`
let s:COMPOUND_ASSIGNMENT = '[:=]\s*\%(if\|unless\|for\|while\|until\|'
\                         . 'switch\|try\|class\)\>'

" A postfix condition like `return ... if ...`.
let s:POSTFIX_CONDITION = '\S\s\+\zs\<\%(if\|unless\)\>'

" A single-line else statement like `else ...` but not `else if ...
let s:SINGLE_LINE_ELSE = '^else\s\+\%(\<\%(if\|unless\)\>\)\@!'

" Max lines to look back for a match
let s:MAX_LOOKBACK = 50

" Get the linked syntax name of a character.
function! s:SyntaxName(linenum, col)
  return synIDattr(synIDtrans(synID(a:linenum, a:col, 1)), 'name')
endfunction

" Check if a character is in a comment.
function! s:IsComment(linenum, col)
  return s:SyntaxName(a:linenum, a:col) == 'Comment'
endfunction

" Check if a character is in a string.
function! s:IsString(linenum, col)
  return s:SyntaxName(a:linenum, a:col) == 'Constant'
endfunction

" Check if a character is in a comment or string.
function! s:IsCommentOrString(linenum, col)
  return s:SyntaxName(a:linenum, a:col) =~ 'Comment\|Constant'
endfunction

" Check if a whole line is a comment.
function! s:IsCommentLine(linenum)
  " Check the first non-whitespace character.
  return s:IsComment(a:linenum, indent(a:linenum) + 1)
endfunction

" Repeatedly search a line for a regex until one is found outside a string or
" comment.
function! s:SmartSearch(linenum, regex)
  " Start at the first column.
  let col = 0

  " Search until there are no more matches, unless a good match is found.
  while 1
    call cursor(a:linenum, col + 1)
    let [_, col] = searchpos(a:regex, 'cn', a:linenum)

    " No more matches.
    if !col
      break
    endif

    if !s:IsCommentOrString(a:linenum, col)
      return 1
    endif
  endwhile

  " No good match found.
  return 0
endfunction

" Skip a match if it's in a comment or string, is a single-line statement that
" isn't adjacent, or is a postfix condition.
function! s:ShouldSkip(startlinenum, linenum, col)
  if s:IsCommentOrString(a:linenum, a:col)
    return 1
  endif

  " Check for a single-line statement that isn't adjacent.
  if s:SmartSearch(a:linenum, '\<then\>') && a:startlinenum - a:linenum > 1
    return 1
  endif

  if s:SmartSearch(a:linenum, s:POSTFIX_CONDITION) &&
  \ !s:SmartSearch(a:linenum, s:COMPOUND_ASSIGNMENT)
    return 1
  endif

  return 0
endfunction

" Find the farthest line to look back to, capped to line 1 (zero and negative
" numbers cause bad things).
function! s:MaxLookback(startlinenum)
  return max([1, a:startlinenum - s:MAX_LOOKBACK])
endfunction

" Get the skip expression for searchpair().
function! s:SkipExpr(startlinenum)
  return "s:ShouldSkip(" . a:startlinenum . ", line('.'), col('.'))"
endfunction

" Search for pairs of text.
function! s:SearchPair(start, end)
  " The cursor must be in the first column for regexes to match.
  call cursor(0, 1)

  let startlinenum = line('.')

  " Don't need the W flag since MaxLookback caps the search to line 1.
  return searchpair(a:start, '', a:end, 'bcn',
  \                 s:SkipExpr(startlinenum),
  \                 s:MaxLookback(startlinenum))
endfunction

" Try to find a previous matching line.
function! s:GetMatch(curline)
  let firstchar = a:curline[0]

  if firstchar == '}'
    return s:SearchPair('{', '}')
  elseif firstchar == ')'
    return s:SearchPair('(', ')')
  elseif firstchar == ']'
    return s:SearchPair('\[', '\]')
  elseif a:curline =~ '^else\>'
    return s:SearchPair('\<\%(if\|unless\|when\)\>', '\<else\>')
  elseif a:curline =~ '^catch\>'
    return s:SearchPair('\<try\>', '\<catch\>')
  elseif a:curline =~ '^finally\>'
    return s:SearchPair('\<try\>', '\<finally\>')
  endif

  return 0
endfunction

" Get the nearest previous line that isn't a comment.
function! s:GetPrevNormalLine(startlinenum)
  let curlinenum = a:startlinenum

  while curlinenum > 0
    let curlinenum = prevnonblank(curlinenum - 1)

    if !s:IsCommentLine(curlinenum)
      return curlinenum
    endif
  endwhile

  return 0
endfunction

" Get the contents of a line without leading or trailing whitespace.
function! s:GetTrimmedLine(linenum)
  return substitute(substitute(getline(a:linenum), '^\s\+', '', ''),
  \                                                '\s\+$', '', '')
endfunction

function! s:GetCoffeeIndent(curlinenum)
  let prevlinenum = s:GetPrevNormalLine(a:curlinenum)

  " Don't do anything if there is no previous line.
  if !prevlinenum
    return -1
  endif

  let curline = s:GetTrimmedLine(a:curlinenum)

  " Try to find a matching pair.
  let matchlinenum = s:GetMatch(curline)

  if matchlinenum
    return indent(matchlinenum)
  endif

  " Try to find a matching `when`.
  if curline =~ '^when\>' && !s:SmartSearch(prevlinenum, '\<switch\>')
    let linenum = a:curlinenum

    while linenum > 0
      let linenum = s:GetPrevNormalLine(linenum)

      if getline(linenum) =~ '^\s*when\>'
        return indent(linenum)
      endif
    endwhile
  endif

  let prevline = s:GetTrimmedLine(prevlinenum)
  let previndent = indent(prevlinenum)

  " Try indenting logic.
  if prevline =~ s:CONTINUATION
    let prevprevlinenum = s:GetPrevNormalLine(prevlinenum)
    let prevprevline = s:GetTrimmedLine(prevprevlinenum)

    if prevprevline !~ s:CONTINUATION && prevprevline !~ s:CONTINUATION_BLOCK
      return previndent + &shiftwidth
    endif
  elseif prevline =~ s:INDENT_AFTER || prevline =~ s:COMPOUND_ASSIGNMENT
    if !s:SmartSearch(prevlinenum, '\<then\>') && prevline !~ s:SINGLE_LINE_ELSE
      return previndent + &shiftwidth
    endif
  elseif curline =~ s:DOT_ACCESS && prevline !~ s:DOT_ACCESS
    return previndent + &shiftwidth
  elseif prevline =~ s:OUTDENT_AFTER
    if !s:SmartSearch(prevlinenum, s:POSTFIX_CONDITION) ||
    \   s:SmartSearch(prevlinenum, '\<then\>')
      return previndent - &shiftwidth
    endif
  endif

  " No indenting or outdenting is needed
  return -1
endfunction

" Wrap s:GetCoffeeIndent to keep the cursor position.
function! GetCoffeeIndent(curlinenum)
  let oldcursor = getpos('.')
  let indent = s:GetCoffeeIndent(a:curlinenum)
  call setpos('.', oldcursor)

  return indent
endfunction

