" ==============================================================================
" Name:        ShowMarks
" Description: Visually displays the location of marks local to a buffer.
" Authors:     Anthony Kruize <trandor@labyrinth.net.au>
"              Michael Geddes <michaelrgeddes@optushome.com.au>
" Version:     1.0
" Modified:    21 November 2001
" License:     Released into the public domain.
" Usage:       Copy this file into the plugins directory so it will be
"              automatically sourced.
"
"              Default keymappings are:
"                <Leader>mt  - Toggles ShowMarks on and off.
"                <Leader>mh  - Hides a mark.
"
"              Hiding a mark doesn't actually remove it, it simply moves it to
"              line 1 and hides it visually.
"
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showmarks" )
	finish
endif
let loaded_showmarks = 1

" Mappings
if !hasmapto( '<Plug>ShowmarksShowMarksToggle')
	map <unique> <leader>mt <Plug>ShowmarksShowMarksToggle
endif
if !hasmapto( '<Plug>ShowmarksHideMark')
	map <unique> <leader>mh <Plug>ShowmarksHideMark
endif

noremap <unique> <script> <Plug>ShowmarksShowMarksToggle :call <SID>ShowMarksToggle()<CR>
noremap <unique> <script> <Plug>ShowmarksHideMark :call <SID>HideMark()<CR>

" AutoCommands: This will check the marks and set the signs
aug ShowMarks
	autocmd CursorHold * call s:ShowMarks()
aug END

" Toggle whether we display marks
function! s:ShowMarksToggle()
	if !exists("b:ShowMarks_Enabled")
		let b:ShowMarks_Enabled = 1
	endif

	if b:ShowMarks_Enabled == 0
		let b:ShowMarks_Enabled = 1
		aug ShowMarks
			autocmd CursorHold * call s:ShowMarks()
		aug END
	else
		let b:ShowMarks_Enabled = 0
		let n = 0
		while n < 26
			let c = nr2char(char2nr('a') + n)
			let id = n * 26 + winbufnr(0)
			if exists('b:placed_'.c)
				let b:placed_{c} = 1
				exe 'sign unplace '.id.' buffer='.winbufnr(0)
			endif
			let n = n + 1
		endwhile
		aug ShowMarks
			autocmd!
		aug END
	endif
endfunction

" Highlighting: Setup some nice colours to show the mark position.
hi default ShowMarksHL ctermfg=blue ctermbg=lightblue cterm=bold guifg=blue guibg=lightblue gui=bold

" Setup the sign definitions for each mark
function! s:ShowMarksSetup()
	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		exe 'sign define ShowMark'.c.' text='.c.'> texthl=ShowMarksHL'
		let n = n + 1
	endwhile
endfunction

call s:ShowMarksSetup()

" This function is called on the CursorHold autocommand.
" It runs through all the marks and displays or removes signs as appropriate.
function! s:ShowMarks()
	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		let id = n * 26 + winbufnr(0)
		let curline = line("'".c)
		if curline != 0 && (!exists('b:placed_'.c) || b:placed_{c} != curline )
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			exe 'sign place '.id.' name=ShowMark'.c.' line='.line("'".c).' buffer='.winbufnr(0)
		endif
		let b:placed_{c} = curline
		let n = n + 1
	endwhile
endfunction

" Hide the mark at the current line.
" This simply moves the mark to line 1 and hides the sign.
function! s:HideMark()
	let curline = line(".")
	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		let markline = line("'".c)
		if curline == markline
			let id = n * 26 + winbufnr(0)
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			exe '1 mark '.c
			let b:placed_{c} = 1
		endif
		let n = n + 1
	endwhile
endfunction
