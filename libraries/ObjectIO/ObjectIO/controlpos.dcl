definition module controlpos


//	Clean Object I/O library, version 1.2


import	ossystem, ostoolbox
import	windowhandle


/*	movewindowviewframe moves the current view frame of the WindowHandle by the given Vector. 
*/
movewindowviewframe	:: !OSWindowMetrics !Vector2 !WIDS !(WindowHandle .ls .pst) !*OSToolbox -> (!WindowHandle .ls .pst, !*OSToolbox)

