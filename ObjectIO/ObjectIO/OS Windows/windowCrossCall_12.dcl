definition module windowCrossCall_12


from	StdString		import String
from	ostoolbox		import OSToolbox
from	ostypes			import HWND
from	rgnCCall_12		import HRGN
from	pictCCall_12	import HDC


//	Cursor shape constants:
CURSHIDDEN			:== 6
CURSARROW			:== 5
CURSFATCROSS		:== 4
CURSCROSS			:== 3
CURSIBEAM			:== 2
CURSBUSY			:== 1

//	Constants for handling scrollbars.
SB_HORZ				:== 0
SB_VERT				:== 1
SB_CTL				:== 2
SB_BOTH				:== 3

SB_LINEUP			:== 0
SB_LINELEFT			:== 0
SB_LINEDOWN			:== 1
SB_LINERIGHT		:== 1
SB_PAGEUP			:== 2
SB_PAGELEFT			:== 2
SB_PAGEDOWN			:== 3
SB_PAGERIGHT		:== 3
SB_THUMBPOSITION	:== 4
SB_THUMBTRACK		:== 5
SB_TOP				:== 6
SB_LEFT				:== 6
SB_BOTTOM			:== 7
SB_RIGHT			:== 7
SB_ENDSCROLL		:== 8

//	PA: constants for handling window styles.
WS_OVERLAPPED		:== 0x00000000
WS_POPUP			:== 0x80000000
WS_CHILD			:== 0x40000000
WS_MINIMIZE			:== 0x20000000
WS_VISIBLE			:== 0x10000000
WS_DISABLED			:== 0x08000000
WS_CLIPSIBLINGS		:== 0x04000000
WS_CLIPCHILDREN		:== 0x02000000
WS_MAXIMIZE			:== 0x01000000
WS_CAPTION			:== 0x00C00000		/* WS_BORDER | WS_DLGFRAME  */
WS_BORDER			:== 0x00800000
WS_DLGFRAME			:== 0x00400000
WS_VSCROLL			:== 0x00200000
WS_HSCROLL			:== 0x00100000
WS_SYSMENU			:== 0x00080000
WS_THICKFRAME		:== 0x00040000
WS_GROUP			:== 0x00020000
WS_TABSTOP			:== 0x00010000

WS_MINIMIZEBOX		:== 0x00020000
WS_MAXIMIZEBOX		:== 0x00010000

WS_TILED			:== WS_OVERLAPPED
WS_ICONIC			:== WS_MINIMIZE
WS_SIZEBOX			:== WS_THICKFRAME
//	PA: end of addition.

//	PA: constants for stacking windows.
HWND_TOP			:==	0
HWND_BOTTOM			:==	1
HWND_TOPMOST		:== -1
HWND_NOTOPMOST		:==	-2
//	PA: end of addition.

//	PA: flag values for passing information about edit controls from Clean to OS.
EDITISMULTILINE		:==	1			/* PA: flag value: edit control is multi-line. */
EDITISKEYSENSITIVE	:==	2			/* PA: flag value: edit control sends keyboard events to Clean. */
//	PA: end of addition.

//	PA: values for telling Windows if a (custom)button control is OK, CANCEL, or normal. 
ISNORMALBUTTON		:==	0			/* The button is a normal button.   */
ISOKBUTTON			:==	1			/* The button is the OK button.     */
ISCANCELBUTTON		:==	2			/* The button is the CANCEL button. */
//	PA: end of addition


WinSetWindowCursor		:: !HWND !Int						!*OSToolbox -> *OSToolbox
WinObscureCursor		::									!*OSToolbox -> *OSToolbox
WinSetWindowTitle		:: !HWND !String					!*OSToolbox -> *OSToolbox
WinGetWindowText		:: !HWND							!*OSToolbox -> (!String, !*OSToolbox)
WinInvalidateWindow		:: !HWND							!*OSToolbox -> *OSToolbox
//	PA: new function to invalidate portion of window/control:
WinInvalidateRect		:: !HWND !(!Int,!Int,!Int,!Int)		!*OSToolbox -> *OSToolbox
//	PA: two new functions to validate parts of a window, using a Rect and a Rgn argument.
WinValidateRect			:: !HWND !(!Int,!Int,!Int,!Int)		!*OSToolbox -> *OSToolbox
WinValidateRgn			:: !HWND !HRGN						!*OSToolbox -> *OSToolbox
//	PA: new function to update part of a window.
WinUpdateWindowRect		:: !HWND !(!Int,!Int,!Int,!Int)		!*OSToolbox -> *OSToolbox
//	PA: new function to (en/dis)able windows.
WinSetSelectStateWindow :: !HWND !(!Bool,!Bool) !Bool !Bool	!*OSToolbox -> *OSToolbox
WinBeginPaint			:: !HWND							!*OSToolbox -> (!HDC, !*OSToolbox) 
WinEndPaint				:: !HWND					!(!HDC, !*OSToolbox) -> *OSToolbox
WinGetDC				:: !HWND							!*OSToolbox -> (!HDC, !*OSToolbox) 
WinReleaseDC			:: !HWND					!(!HDC, !*OSToolbox) -> *OSToolbox
WinGetClientSize		:: !HWND							!*OSToolbox -> (!(!Int,!Int), !*OSToolbox)
WinGetWindowSize		:: !HWND							!*OSToolbox -> (!(!Int,!Int), !*OSToolbox)	// PA: added; returns bounding size of window
WinSetClientSize		:: !HWND !(!Int,!Int)				!*OSToolbox -> *OSToolbox					// PA: added
WinSetWindowSize		:: !HWND !(!Int,!Int) !Bool			!*OSToolbox -> *OSToolbox					// PA: added
WinGetWindowPos			:: !HWND							!*OSToolbox -> (!(!Int,!Int), !*OSToolbox)
WinSetWindowPos			:: !HWND !(!Int,!Int) !Bool !Bool	!*OSToolbox -> *OSToolbox
/*	PA: three new functions to handle scrollbars.
*/
WinSetScrollRange		:: !HWND !Int !Int !Int !Bool		!*OSToolbox -> *OSToolbox
WinSetScrollPos			:: !HWND !Int !Int !Int !Int !Int	!*OSToolbox -> *OSToolbox
WinSetScrollThumbSize	:: !HWND !Int !Int !Int !Int !Int	!*OSToolbox -> *OSToolbox
/*	PA: new functions to handle edit controls.
*/
WinSetEditSelection		:: !HWND !Int !Int					!*OSToolbox -> *OSToolbox		// Note: @2<=@3, @1 must point to an edit control.

WinRestackWindow		:: !HWND !HWND						!*OSToolbox -> *OSToolbox		// PA: new function to put first window behind second window

WinShowControl			:: !HWND !Bool						!*OSToolbox -> *OSToolbox	// PA: new routine to hide (False) & show (True) controls.
WinEnableControl		:: !HWND !Bool						!*OSToolbox -> *OSToolbox
WinEnablePopupItem		:: !HWND !Int !Bool					!*OSToolbox -> *OSToolbox	// PA: this function is currently not used, but might be
WinCheckControl			:: !HWND !Bool						!*OSToolbox -> *OSToolbox
WinSelectPopupItem		:: !HWND !Int						!*OSToolbox -> *OSToolbox
