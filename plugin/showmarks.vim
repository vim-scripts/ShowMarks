" ==============================================================================
" Name:        ShowMarks
" Description: Visually displays the location of marks local to a buffer.
" Authors:     Anthony Kruize <trandor@labyrinth.net.au>
"              Michael Geddes <michaelrgeddes@optushome.com.au>
" Version:     1.4
" Modified:    22 May 2002
" License:     Released into the public domain.
" ChangeLog:   1.4 - Added support for placing the next available mark.
"                      (Thanks to Shishir Ramam for the idea)
"                    Added support for hiding all marks.
"                    Marks on line 1 are no longer shown. This stops hidden
"                      marks from reappearing when the file is opened again.
"                    Added a help file.
"              1.3 - Fixed toggling ShowMarks not responding immediately.
"                    Added user commands for toggling/hiding marks.
"                    Added ability to disable ShowMarks by default.
"              1.2 - Added a check that Vim was compiled with +signs support.
"                    Added the ability to define which marks are shown.
"                    Removed debugging code I accidently left in.
"              1.1 - Added support for the A-Z marks.
"                    Fixed sign staying placed if the line it was on is deleted.
"                    Clear autocommands before making new ones.
"              1.0 - First release.
"
" Usage:       Copy this file into the plugins directory so it will be
"              automatically sourced.
"
"              Default keymappings are:
"                <Leader>mt  - Toggles ShowMarks on and off.
"                <Leader>mh  - Hides a mark.
"                <Leader>ma  - Hides all marks.
"                <Leader>mm  - Places the next available mark.
"
"              Hiding a mark doesn't actually remove it, it simply moves it
"              to line 1 and hides it visually.
"
" Configuration: The following options can be used to customize the
"              behavior of ShowMarks.  Simply include them in your vimrc
"              file with the desired settings.
"
"              showmarks_enable  (Default: 1)
"                   Defines whether ShowMarks is enabled by default or not.
"                   Example: let showmarks_enable=0
"              showmarks_include (Default: "a-zA-Z")
"                   Defines which marks will be shown.
"                   Example: let showmarks_include="a-dmtuA-E"
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showmarks" )
	finish
endif
let loaded_showmarks = 1

" Bail out if Vim isn't compiled with signs support.
if has( "signs" ) == 0
	echohl ErrorMsg
	echo "ShowMarks requires Vim to have +signs support."
	echohl None
	finish
endif

" Enable showmarks by default.
if !exists('g:showmarks_enable')
	let g:showmarks_enable = 1
endif
" Show all marks by default.
if !exists('g:showmarks_include')
	let g:showmarks_include = "a-zA-Z"
endif

" Commands
com! -nargs=0 ShowMarksToggle :silent call <sid>ShowMarksToggle()
com! -nargs=0 ShowMarksHideMark :silent call <sid>ShowMarksHideMark()
com! -nargs=0 ShowMarksHideAll :silent call <sid>ShowMarksHideAll()
com! -nargs=0 ShowMarksPlaceMark :silent call <sid>ShowMarksPlaceMark()

" Mappings
if !hasmapto( '<Plug>ShowmarksShowMarksToggle' )
	map <silent> <unique> <leader>mt <Plug>ShowmarksShowMarksToggle
endif
if !hasmapto( '<Plug>ShowmarksHideMark' )
	map <silent> <unique> <leader>mh <Plug>ShowmarksShowMarksHideMark
endif
if !hasmapto( '<Plug>ShowmarksHideAll' )
	map <silent> <unique> <leader>ma <Plug>ShowmarksShowMarksHideAll
endif
if !hasmapto( '<Plug>ShowmarksPlaceMark' )
	map <silent> <unique> <leader>mm <Plug>ShowmarksShowMarksPlaceMark
endif
noremap <unique> <script> <Plug>ShowmarksShowMarksToggle :call <sid>ShowMarksToggle()<CR>
noremap <unique> <script> <Plug>ShowmarksShowMarksHideMark :call <sid>ShowMarksHideMark()<CR>
noremap <unique> <script> <Plug>ShowmarksShowMarksHideAll :call <sid>ShowMarksHideAll()<CR>
noremap <unique> <script> <Plug>ShowmarksShowMarksPlaceMark :call <sid>ShowMarksPlaceMark()<CR>
noremap <unique> <script> \sm m
noremap <silent> m :exe 'norm \sm'.nr2char(getchar())<bar>call <sid>ShowMarks()<CR>

" AutoCommands
aug ShowMarks
	au!
	autocmd CursorHold * call s:ShowMarks()
aug END

" Highlighting: Setup some nice colours to show the mark position.
hi default ShowMarksHL ctermfg=blue ctermbg=lightblue cterm=bold guifg=blue guibg=lightblue gui=bold

" Function: ShowMarksSetup()
" Description: This function sets up the sign definitions for each mark.
fun! s:ShowMarksSetup()
	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		let C = nr2char(char2nr('A') + n)
		exe 'sign define ShowMark'.c.' text='.c.'> texthl=ShowMarksHL'
		exe 'sign define ShowMark'.C.' text='.C.'> texthl=ShowMarksHL'
		let n = n + 1
	endw
endf

" Set things up
call s:ShowMarksSetup()

" Function: ShowMarksToggle()
" Description: This function toggles whether marks are displayed or not.
fun! s:ShowMarksToggle()
	if g:showmarks_enable == 0
		let g:showmarks_enable = 1
		call <sid>ShowMarks()
		aug ShowMarks
			autocmd CursorHold * call s:ShowMarks()
		aug END
	else
		let g:showmarks_enable = 0
		let n = 0
		while n < 26
			let c = nr2char(char2nr('a') + n)
			let C = nr2char(char2nr('A') + n)
			let id = n + 52 * winbufnr(0)
			let ID = id + 26
			if exists('b:placed_'.c)
				let b:placed_{c} = 1
				exe 'sign unplace '.id.' buffer='.winbufnr(0)
			endif
			if exists('b:placed_'.C)
				let b:placed_{C} = 1
				exe 'sign unplace '.ID.' buffer='.winbufnr(0)
			endif
			let n = n + 1
		endw
		aug ShowMarks
			au!
		aug END
	endif
endf

" Function: ShowMarks()
" Description: This function runs through all the marks and displays or
" removes signs as appropriate. It is called on the CursorHold autocommand.
fun! s:ShowMarks()
	if g:showmarks_enable == 0
		return
	endif

	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		let id = n + 52 * winbufnr(0)
		let ln = line("'".c)
		let C = nr2char(char2nr('A') + n)
		let ID = id + 26
		let LN = line("'".C)

		if c =~ '^['.g:showmarks_include.']$'
			if ln == 0 && (exists('b:placed_'.c) && b:placed_{c} != ln )
				exe 'sign unplace '.id.' buffer='.winbufnr(0)
			elseif ln > 1 && (!exists('b:placed_'.c) || b:placed_{c} != ln )
				exe 'sign unplace '.id.' buffer='.winbufnr(0)
				exe 'sign place '.id.' name=ShowMark'.c.' line='.ln.' buffer='.winbufnr(0)
			endif
		endif

		if C =~ '^['.g:showmarks_include.']$'
			if LN == 0 && (exists('b:placed_'.C) && b:placed_{C} != LN )
				exe 'sign unplace '.ID.' buffer='.winbufnr(0)
			elseif LN > 1 && (!exists('b:placed_'.C) || b:placed_{C} != LN )
				exe 'sign unplace '.ID.' buffer='.winbufnr(0)
				exe 'sign place '.ID.' name=ShowMark'.C.' line='.LN.' buffer='.winbufnr(0)
			endif
		endif

		let b:placed_{c} = ln
		let b:placed_{C} = LN
		let n = n + 1
	endw
endf

" Function: ShowMarksHideMark()
" Description: This function hides the mark at the current line.
" It simply moves the mark to line 1 and hides the sign.
fun! s:ShowMarksHideMark()
	let ln = line(".")
	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		let C = nr2char(char2nr('A') + n)
		let markln = line("'".c)
		let markLN = line("'".C)
		if ln == markln
			let id = n + 52 * winbufnr(0)
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			exe '1 mark '.c
			let b:placed_{c} = 1
		endif
		if ln == markLN
			let ID = (n + 52 * winbufnr(0)) + 26
			exe 'sign unplace '.ID.' buffer='.winbufnr(0)
			exe '1 mark '.C
			let b:placed_{C} = 1
		endif
		let n = n + 1
	endw
endf

" Function: ShowMarksHideAll()
" Description: This function hides all marks in the buffer.
" It simply moves the marks to line 1 and hides the signs.
fun! s:ShowMarksHideAll()
	let n = 0
	while n < 26
		let c = nr2char(char2nr('a') + n)
		let id = n + 52 * winbufnr(0)
		let C = nr2char(char2nr('A') + n)
		let ID = (n + 52 * winbufnr(0)) + 26

		exe 'sign unplace '.id.' buffer='.winbufnr(0)
		exe '1 mark '.c
		let b:placed_{c} = 1

		exe 'sign unplace '.ID.' buffer='.winbufnr(0)
		exe '1 mark '.C
		let b:placed_{C} = 1

		let n = n + 1
	endw
endf

" Function: ShowMarksPlaceMark()
" Description: This function will place the next unplaced mark to the current
" location. The idea here is to automate the placement of marks so the user
" doesn't have to remember which marks are placed or not.
" Hidden marks are considered to be unplaced.
" Marks A-Z aren't supported.
fun! s:ShowMarksPlaceMark()
	let n = 0
	let p = 0
	while n < 26 && p == 0
		let c = nr2char(char2nr('a') + n)
		let ln = line("'".c)
		if ln <= 1
			exe 'mark '.c
			call <sid>ShowMarks()
			let p = 1
		endif
		let n = n + 1
	endw
endf
