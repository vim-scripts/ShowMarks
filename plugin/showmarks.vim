" ==============================================================================
" Name:          ShowMarks
" Description:   Visually displays the location of marks.
" Authors:       Anthony Kruize <trandor@labyrinth.net.au>
"                Michael Geddes <michaelrgeddes@optushome.com.au>
" Version:       2.0
" Modified:      11 August 2003
" License:       Released into the public domain.
" ChangeLog:     2.0 - Added ability to ignore buffers by type.
"                      Toggling ShowMarks off now works correctly when
"                        switching buffers.
"                      ShowMarksHideMark and ShowMarksHideAll have been
"                        renamed to ShowMarksClearMark and ShowMarksClearAll.
"                      Marks a-z, A-Z and others can now have different
"                        highlighting from each other.
"                      Added support for all other marks. (Gary Holloway)
"                      Enhanced customization of how marks are displayed by
"                        allowing a prefix to be specified.(GH & AK)
"                      Fixed CursorHold autocmd triggering even when ShowMarks
"                        is disabled. (Charles E. Campbell)
"                1.5 - Added ability to customize how the marks are displayed.
"                1.4 - Added support for placing the next available mark.
"                        (Thanks to Shishir Ramam for the idea)
"                      Added support for hiding all marks.
"                      Marks on line 1 are no longer shown. This stops hidden
"                        marks from reappearing when the file is opened again.
"                      Added a help file.
"                1.3 - Fixed toggling ShowMarks not responding immediately.
"                      Added user commands for toggling/hiding marks.
"                      Added ability to disable ShowMarks by default.
"                1.2 - Added a check that Vim was compiled with +signs support.
"                      Added the ability to define which marks are shown.
"                      Removed debugging code I accidently left in.
"                1.1 - Added support for the A-Z marks.
"                      Fixed sign staying placed if the line it was on is
"                        deleted.
"                      Clear autocommands before making new ones.
"                1.0 - First release.
"
" Usage:         Copy this file into the plugins directory so it will be
"                automatically sourced.
"
"                Default keymappings are:
"                  <Leader>mt  - Toggles ShowMarks on and off.
"                  <Leader>mh  - Clears a mark.
"                  <Leader>ma  - Clears all marks.
"                  <Leader>mm  - Places the next available mark.
"
"                Hiding a mark doesn't actually remove it, it simply moves it
"                to line 1 and hides it visually.
"
" Configuration: ***********************************************************
"                * PLEASE read the included help file(showmarks.txt) for a *
"                * more thorough explanation of how to use ShowMarks.      *
"                ***********************************************************
"                The following options can be used to customize the behavior
"                of ShowMarks.  Simply include them in your vimrc file with
"                the desired settings.
"
"                showmarks_enable (Default: 1)
"                   Defines whether ShowMarks is enabled by default.
"                   Example: let g:showmarks_enable=0
"                showmarks_include (Default: "a-zA-Z")
"                   Defines which marks will be shown.
"                   Example: let g:showmarks_include="a-dmtuA-E"
"                showmarks_ignore_type (Default: "hq")
"                   Defines the buffer types to be ignored.
"                   Valid types are:
"                     h - Help            p - preview
"                     q - quickfix        r - readonly
"                     m - non-modifiable
"                showmarks_ignore_name (Default: "")
"                   Defines a list of space separated buffer names to ignore.
"                   Example: let g:showmarks_ignore_name="__Tag_List__"
"                showmarks_textlower (Default: ">")
"                   Defines how the mark is to be displayed.
"                   A maximum of two characters can be displayed. To include
"                   the mark in the text use a tab(\t) character. A single
"                   character will display as the mark with the character
"                   suffixed (same as "\t<character>")
"                   Examples:
"                    To display the mark with a > suffixed:
"                      let g:showmarks_textlower="\t>"
"                         or
"                      let g:showmarks_textlower=">"
"                    To display the mark with a ( prefixed:
"                      let g:showmarks_textlower="(\t"
"                    To display two > characters:
"                      let g:showmarks_textlower=">>"
"                showmarks_textupper (Default: ">")
"                   Same as above but for the marks A-Z.
"                   Example: let g:showmarks_textupper="**"
"                showmarks_textother (Default: ">")
"                   Same as above but for all other marks.
"                   Example: let g:showmarks_textother="--"
"
"                Setting Highlighting Colours
"                   ShowMarks uses the following highlighting groups:
"                     ShowMarksHL  - For marks a-z
"                     ShowMarksHLu - For marks A-Z
"                     ShowMarksHLo - For all other marks
"
"                   By default they are set to a bold blue on light blue.
"                   Defining a highlight for each of these groups will
"                   override the default highlighting.
"                   See the VIM help for more information about highlighting.
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showmarks" )
	finish
endif
let loaded_showmarks = 1

" Bail if Vim isn't compiled with signs support.
if has( "signs" ) == 0
	echohl ErrorMsg
	echo "ShowMarks requires Vim to have +signs support."
	echohl None
	finish
endif

" All possible mark characters.(ShowMarksPlaceMark requires [a-z] to be first)
let s:allmarks = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[]<>`'\"^.(){}"
let s:maxmarks = strlen(s:allmarks)

" Options: Set up some nice defaults
if !exists('g:showmarks_enable')
	let g:showmarks_enable = 1
endif
if !exists('g:showmarks_include')
	let g:showmarks_include = "a-zA-Z"
endif
if !exists('g:showmarks_textlower')
	let g:showmarks_textlower = ">"
endif
if !exists('g:showmarks_textupper')
	let g:showmarks_textupper = ">"
endif
if !exists('g:showmarks_textother')
	let g:showmarks_textother=">"
endif
if !exists('g:showmarks_ignore_type')
	let g:showmarks_ignore_type="hq"
endif
if !exists('g:showmarks_ignore_name')
	let g:showmarks_ignore_name=""
endif

" Commands
com! -nargs=0 ShowMarksToggle :silent call <sid>ShowMarksToggle()
com! -nargs=0 ShowMarksClearMark :silent call <sid>ShowMarksClearMark()
com! -nargs=0 ShowMarksClearAll :silent call <sid>ShowMarksClearAll()
com! -nargs=0 ShowMarksPlaceMark :silent call <sid>ShowMarksPlaceMark()

" Mappings
if !hasmapto( '<Plug>ShowmarksShowMarksToggle' )
	map <silent> <unique> <leader>mt :ShowMarksToggle<cr>
endif
if !hasmapto( '<Plug>ShowmarksClearMark' )
	map <silent> <unique> <leader>mh :ShowMarksClearMark<cr>
endif
if !hasmapto( '<Plug>ShowmarksClearAll' )
	map <silent> <unique> <leader>ma :ShowMarksClearAll<cr>
endif
if !hasmapto( '<Plug>ShowmarksPlaceMark' )
	map <silent> <unique> <leader>mm :ShowMarksPlaceMark<cr>
endif
noremap <unique> <script> \sm m
noremap <silent> m :exe 'norm \sm'.nr2char(getchar())<bar>call <sid>ShowMarks()<CR>

" AutoCommands: Only if ShowMarks is enabled
if g:showmarks_enable == 1
	aug ShowMarks
		au!
		autocmd CursorHold * call s:ShowMarks()
	aug END
endif

" Highlighting: Setup some nice colours to show the mark positions.
hi default ShowMarksHL  ctermfg=darkblue ctermbg=blue cterm=bold guifg=blue guibg=lightblue gui=bold
hi default ShowMarksHLu ctermfg=darkblue ctermbg=blue cterm=bold guifg=blue guibg=lightblue gui=bold
hi default ShowMarksHLo ctermfg=darkblue ctermbg=blue cterm=bold guifg=blue guibg=lightblue gui=bold

" Function: NameOfMark()
" Paramaters: mark - Specifies the mark to find the name of.
" Description: Convert marks that cannot be used as part of a variable name to
" something that can be. i.e. We cannot use [ as a variable-name suffix (as
" in 'placed_['; this routine will return something like 63, so the variable
" will be something like 'placed_63').
fun! s:NameOfMark(mark)
	let name = a:mark
	if a:mark =~ '\W'
		let name = stridx(s:allmarks, a:mark)
	endif
	return name
endf

" Function: VerifyText()
" Paramaters: which - Specifies the variable to verify.
" Description: Verify the validity of a showmarks_text{upper,lower,other} setup variable.
" Default to ">" if it is found to be invalid.
fun! s:VerifyText(which)
	if strlen(g:showmarks_text{a:which}) == 0 || strlen(g:showmarks_text{a:which}) > 2
		echohl ErrorMsg
		echo "ShowMarks: text".a:which." must contain only 1 or 2 characters."
		echohl None
		let g:showmarks_text{a:which}=">"
	endif
endf

" Function: ShowMarksSetup()
" Description: This function sets up the sign definitions for each mark.
" It uses the showmarks_textlower, showmarks_textupper and showmarks_textother
" variables to determine how to draw the mark.
fun! s:ShowMarksSetup()
	let n = 0

	" Make sure the textlower, textupper, and textother options are valid.
	call s:VerifyText('lower')
	call s:VerifyText('upper')
	call s:VerifyText('other')

	while n < s:maxmarks
		let c = strpart(s:allmarks, n, 1)
		let nm = s:NameOfMark(c)
		let text = '>'.c
		if c =~ '[a-z]'
			if strlen(g:showmarks_textlower) == 1
				let text=c.g:showmarks_textlower
			elseif strlen(g:showmarks_textlower) == 2
				let t1 = strpart(g:showmarks_textlower,0,1)
				let t2 = strpart(g:showmarks_textlower,1,1)
				if t1 == "\t"
					let text=c.t2
				elseif t2 == "\t"
					let text=t1.c
				else
					let text=g:showmarks_textlower
				endif
			endif
			exe 'sign define ShowMark'.nm.' text='.text.' texthl=ShowMarksHL'
		elseif c =~ '[A-Z]'
			if strlen(g:showmarks_textupper) == 1
				let text=c.g:showmarks_textupper
			elseif strlen(g:showmarks_textupper) == 2
				let t1 = strpart(g:showmarks_textupper,0,1)
				let t2 = strpart(g:showmarks_textupper,1,1)
				if t1 == "\t"
					let text=c.t2
				elseif t2 == "\t"
					let text=t1.c
				else
					let text=g:showmarks_textupper
				endif
			endif
			exe 'sign define ShowMark'.nm.' text='.text.' texthl=ShowMarksHLu'
		else " Other signs, like ', ., etc.
			if strlen(g:showmarks_textother) == 1
				let text=c.g:showmarks_textother
			elseif strlen(g:showmarks_textother) == 2
				let t1 = strpart(g:showmarks_textother,0,1)
				let t2 = strpart(g:showmarks_textother,1,1)
				if t1 == "\t"
					let text=c.t2
				elseif t2 == "\t"
					let text=t1.c
				else
					let text=g:showmarks_textother
				endif
			endif
			exe 'sign define ShowMark'.nm.' text='.text.' texthl=ShowMarksHLo'
		endif
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
			au!
			autocmd CursorHold * call s:ShowMarks()
		aug END
	else
		let g:showmarks_enable = 0
		call <sid>ShowMarksHideAll()
		aug ShowMarks
			au!
			autocmd BufEnter * call s:ShowMarksHideAll()
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

	if ((match(g:showmarks_ignore_type, "[Hh]") > -1) && (&buftype == "help")) || ((match(g:showmarks_ignore_type, "[Qq]") > -1) && (&buftype == "quickfix")) || ((match(g:showmarks_ignore_type, "[Pp]") > -1) && (&pvw == 1)) || ((match(g:showmarks_ignore_type, "[Rr]") > -1) && (&readonly == 1)) || ((match(g:showmarks_ignore_type, "[Mm]") > -1) && (&modifiable == 0))
		return
	endif

"	if match(g:showmarks_ignore_name, bufname("%")) > -1
"		return
"	endif

	let n = 0
	while n < s:maxmarks
		let c = strpart(s:allmarks, n, 1)
		let nm = s:NameOfMark(c)
		let id = n + (s:maxmarks * winbufnr(0))
		let ln = line("'".c)

		if c =~ '^['.g:showmarks_include.']$'
			if ln == 0 && (exists('b:placed_'.nm) && b:placed_{nm} != ln )
				exe 'sign unplace '.id.' buffer='.winbufnr(0)
			elseif ln > 1 && (!exists('b:placed_'.nm) || b:placed_{nm} != ln )
				exe 'sign unplace '.id.' buffer='.winbufnr(0)
				exe 'sign place '.id.' name=ShowMark'.nm.' line='.ln.' buffer='.winbufnr(0)
			endif
		endif

		let b:placed_{nm} = ln
		let n = n + 1
	endw
endf

" Function: ShowMarksClearMark()
" Description: This function hides the a-z or A-Z mark at the current line.
" It simply moves the mark to line 1 and removes the sign.
fun! s:ShowMarksClearMark()
	let ln = line(".")
	let n = 0
	while n < 52
		let c = strpart(s:allmarks, n, 1)
		let nm = s:NameOfMark(c)
		let id = n + (s:maxmarks * winbufnr(0))
		let markln = line("'".c)
		if ln == markln
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			exe '1 mark '.c
			let b:placed_{nm} = 1
		endif
		let n = n + 1
	endw
endf

" Function: ShowMarksClearAll()
" Description: This function clears all a-z and A-Z marks in the buffer.
" It simply moves the marks to line 1 and removes the signs.
fun! s:ShowMarksClearAll()
	let n = 0
	while n < 52
		let c = strpart(s:allmarks, n, 1)
		let nm = s:NameOfMark(c)
		let id = n + (s:maxmarks * winbufnr(0))

		exe 'sign unplace '.id.' buffer='.winbufnr(0)
		exe '1 mark '.c
		let b:placed_{nm} = 1

		let n = n + 1
	endw
endf

" Function: ShowMarksHideAll()
" Description: This function hides all marks in the buffer.
" It simply removes the signs.
fun! s:ShowMarksHideAll()
	let n = 0
	while n < s:maxmarks
		let c = strpart(s:allmarks, n, 1)
		let nm = s:NameOfMark(c)
		let id = n + (s:maxmarks * winbufnr(0))
		if exists('b:placed_'.nm)
			exe 'sign unplace '.id.' buffer='.winbufnr(0)
			unlet b:placed_{nm}
		endif
		let n = n + 1
	endw
endf

" Function: ShowMarksPlaceMark()
" Description: This function will place the next unplaced mark to the current
" location. The idea here is to automate the placement of marks so the user
" doesn't have to remember which marks are placed or not.
" Hidden marks are considered to be unplaced.
" Only marks a-z are supported.
fun! s:ShowMarksPlaceMark()
	let n = 0
	while n < 26
		let c = strpart(s:allmarks, n, 1)
		let ln = line("'".c)
		if ln <= 1
			exe 'mark '.c
			call <sid>ShowMarks()
			break
		endif
		let n = n + 1
	endw
endf

" vim:ts=4:sw=4:noet
