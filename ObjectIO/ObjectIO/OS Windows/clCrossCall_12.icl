implementation module clCrossCall_12

//	Clean Object I/O library, version 1.2

import StdBool, StdClass, StdInt, StdMisc, StdString, StdTuple
import ostoolbox
import code from "cCrossCall_12.obj", "cdebug_12.obj", "cpicture_12.obj", /*"htmlhelp.obj",*/ "util_12.obj",/*MW11*/ "cprinter_12.obj", "cTCP.obj"
import code from library "advapi32_library",
                 library "comctl32_library",
                 library "kernel32_library",
                 library "ole32_library",
                 library "shell32_library",
                 library "winmm_library",
                 library "winspool_library",
                 library "wsock_library",
                 library "kernelExt_library",
                 library "gdiExt_library",
                 library "userExt_library"
/*	PA: these imports have been moved from gameCrossCall_12. */
import code from "cGameLib_12.obj", "cOSGameLib_12.obj", "ddutil.obj", "Dsutil.obj"
import code from library "ddraw_library"
import code from library "dsound_library"
/*	...PA */
//import	StdDebug, tracetypes

  //----------------------------------------------//
 //    Crosscall infrastructure                  //
//----------------------------------------------//

//	CrossCallInfo is the basic record that is passed between the Clean thread and the OS thread:
::	CrossCallInfo
	=	{	ccMsg	:: !Int		// The message nr: Clean->OS use CcRq...; OS->Clean use CcWm...
		,	p1		:: !Int
		,	p2		:: !Int
		,	p3		:: !Int
		,	p4		:: !Int
		,	p5		:: !Int
		,	p6		:: !Int
		}


//	PA: restructured IssueCleanRequest for readability.
//	2 versions: first without Iprint statements, second with Iprint statements.
//	In both cases the Bool result has also been eliminated as it is never used.
IssueCleanRequest :: !(CrossCallInfo -> .(.s -> .(*OSToolbox -> *(.CrossCallInfo,.s,*OSToolbox))))
                     !.CrossCallInfo !.s !*OSToolbox -> (!CrossCallInfo,!.s,!*OSToolbox)
IssueCleanRequest callback cci s tb
//	# tb			= trace_n ("IssueCleanRequest :"+++toOSCrossCallInfoString cci) tb
	# (reply,tb)	= WinKickOsThread cci tb
	= HandleCallBacks callback reply s tb
where
	HandleCallBacks :: !(CrossCallInfo -> .(.s -> .(*OSToolbox -> *(.CrossCallInfo,.s,*OSToolbox))))
					   !CrossCallInfo !.s !*OSToolbox -> (!CrossCallInfo,!.s,!*OSToolbox)
	HandleCallBacks callback cci=:{ccMsg} s tb
		| ccMsg>2000
			= abort ("HandleCallBacks "+++toString ccMsg)
	//	# tb					= trace_n ("IssueCleanRequest <-- "+++toCleanCrossCallInfoString cci) tb
		| IsReturnOrQuitCci ccMsg
			= (cci,s,tb)
		| otherwise
			# (returnCci,s,tb)	= callback cci s tb
		//	# tb				= trace_n ("IssueCleanRequest --> "+++toOSCrossCallInfoString returnCci) tb
			# (replyCci,tb)		= WinKickOsThread returnCci tb
			= HandleCallBacks callback replyCci s tb

/*	PA: version of IssueCleanRequest that has no state parameter.
*/
IssueCleanRequest2 :: !(CrossCallInfo -> .(*OSToolbox -> *(.CrossCallInfo,*OSToolbox))) !.CrossCallInfo !*OSToolbox
																					 -> (!CrossCallInfo,!*OSToolbox)
IssueCleanRequest2 callback cci tb
//	# tb			= trace_n ("IssueCleanRequest2 :"+++toOSCrossCallInfoString cci) tb
	# (reply,tb)	= WinKickOsThread cci tb
	= HandleCallBacks callback reply tb
where
	HandleCallBacks :: !(CrossCallInfo -> .(*OSToolbox -> *(.CrossCallInfo,*OSToolbox))) !CrossCallInfo !*OSToolbox
																					 -> (!CrossCallInfo,!*OSToolbox)
	HandleCallBacks callback cci=:{ccMsg} tb
		| ccMsg>2000
			= abort ("HandleCallBacks "+++toString ccMsg)
	//	# tb					= trace_n ("IssueCleanRequest2 <-- "+++toCleanCrossCallInfoString cci) tb
		| IsReturnOrQuitCci ccMsg
			= (cci,tb)
		| otherwise
			# (returnCci,tb) 	= callback cci tb
		//	# tb				= trace_n ("IssueCleanRequest2 --> "+++toOSCrossCallInfoString returnCci) tb
			# (replyCci, tb) 	= WinKickOsThread returnCci tb
			= HandleCallBacks callback replyCci tb

//	PA: macros for returning proper number of arguments within a CrossCallInfo.
Rq0Cci msg :== {ccMsg=msg,p1=0,p2=0,p3=0,p4=0,p5=0,p6=0}
Rq1Cci msg v1 :== {ccMsg=msg,p1=v1,p2=0,p3=0,p4=0,p5=0,p6=0}
Rq2Cci msg v1 v2 :== {ccMsg=msg,p1=v1,p2=v2,p3=0,p4=0,p5=0,p6=0}
Rq3Cci msg v1 v2 v3 :== {ccMsg=msg,p1=v1,p2=v2,p3=v3,p4=0,p5=0,p6=0}
Rq4Cci msg v1 v2 v3 v4 :== {ccMsg=msg,p1=v1,p2=v2,p3=v3,p4=v4,p5=0,p6=0}
Rq5Cci msg v1 v2 v3 v4 v5 :== {ccMsg=msg,p1=v1,p2=v2,p3=v3,p4=v4,p5=v5,p6=0}
Rq6Cci msg v1 v2 v3 v4 v5 v6 :== {ccMsg=msg,p1=v1,p2=v2,p3=v3,p4=v4,p5=v5,p6=v6}

Return0Cci :: CrossCallInfo
Return0Cci = Rq0Cci CcRETURN0

Return1Cci :: !Int -> CrossCallInfo
Return1Cci v = Rq1Cci CcRETURN1 v

Return2Cci :: !Int !Int -> CrossCallInfo
Return2Cci v1 v2 = Rq2Cci CcRETURN2 v1 v2

Return3Cci :: !Int !Int !Int -> CrossCallInfo
Return3Cci v1 v2 v3 = Rq3Cci CcRETURN3 v1 v2 v3

Return4Cci :: !Int !Int !Int !Int -> CrossCallInfo
Return4Cci v1 v2 v3 v4 = Rq4Cci CcRETURN4 v1 v2 v3 v4

Return5Cci :: !Int !Int !Int !Int !Int -> CrossCallInfo
Return5Cci v1 v2 v3 v4 v5 = Rq5Cci CcRETURN5 v1 v2 v3 v4 v5

Return6Cci :: !Int !Int !Int !Int !Int !Int -> CrossCallInfo
Return6Cci v1 v2 v3 v4 v5 v6 = Rq6Cci CcRETURN6 v1 v2 v3 v4 v5 v6

IsReturnOrQuitCci :: !Int -> Bool
IsReturnOrQuitCci mess
	= mess==CcWASQUIT || (mess<=CcRETURNmax && mess>=CcRETURNmin)

instance toInt Bool where
	toInt :: !Bool -> Int
	toInt True = -1
	toInt _    = 0

ErrorCallback :: !String !CrossCallInfo !.s !*OSToolbox -> (!CrossCallInfo, !.s, !*OSToolbox)
ErrorCallback source cci s tb
	= (Return0Cci, s, Iprint msgtext tb)
where
	msgtext	= " *** [" +++ source +++ "] did not expect a callback: " +++ toString cci.ccMsg

//	PA: version of ErrorCallback without state parameter (use with IssueCleanRequest2).
ErrorCallback2 :: !String !CrossCallInfo !*OSToolbox -> (!CrossCallInfo,!*OSToolbox)
ErrorCallback2 source cci tb
	= (Return0Cci,Iprint msgtext tb)
where
	msgtext	= " *** [" +++ source +++ "] did not expect a callback: " +++ toString cci.ccMsg

Iprint :: !String !.a -> .a
Iprint s a 
	| not (printresult == 0)  = a
							  = abort ("Print failed: " +++ s)
where
	printresult   = ConsolePrint ("## " +++ s +++ "\n") 999

Iprint` :: !String !.a -> .a
Iprint` s a 
	| not (printresult == 0)  = a
							  = abort ("Print failed: " +++ s)
where
	printresult   = ConsolePrint s 999

ConsolePrint ::  !{#Char} !*OSToolbox ->  *OSToolbox
ConsolePrint _ _
	= code
	{
		.inline ConsolePrint
			ccall ConsolePrint "SI-I"
		.end
	}


  //---------------------------------------------------------------------//
 //  Synchronisation operations between the Clean thread and OS thread  //
//---------------------------------------------------------------------//

WinKickOsThread ::  !CrossCallInfo !*OSToolbox -> ( !CrossCallInfo, !*OSToolbox)
WinKickOsThread _ _
	= code
	{
		.inline WinKickOsThread
			ccall WinKickOsThread "IIIIIIII-IIIIIIII"
		.end
	}

WinKillOsThread ::  !*OSToolbox ->  *OSToolbox
WinKillOsThread _
	= code
	{
		.inline WinKillOsThread
			ccall WinKillOsThread "I-I"
		.end
	}

WinStartOsThread ::  !*OSToolbox ->  *OSToolbox
WinStartOsThread _
	= code
	{
		.inline WinStartOsThread
			ccall WinStartOsThread "I-I"
		.end
	}

WinCloseOs ::  !*OSToolbox ->  Bool
WinCloseOs _
	= code
	{
		.inline WinCloseOs
			ccall WinCloseOs "I-I"
		.end
	}

WinInitOs :: ( !Bool, !*OSToolbox)
WinInitOs
	= code
	{
		.inline WinInitOs
			ccall WinInitOs "-II"
		.end
	}

//	PA: added to test refreshing of desktop
WinRefreshDesktop :: !*OSToolbox -> *OSToolbox
WinRefreshDesktop tb
	= snd (IssueCleanRequest2 (ErrorCallback2 "WinRefreshDesktop") (Rq0Cci CcRqUPDATEDESKTOP) tb)


  //------------------------------------------------------------------------//
 //  The message numbers for communication from Clean to OS (ccMsg field)  //
//------------------------------------------------------------------------//
// Mike //
CcRqUSERGAMEEVENT			:== 1905
CcRqCREATEGAMEOBJECT		:== 1904
CcRqPLAYSOUNDSAMPLE			:== 1903

CcRqRUNGAME					:== 1901
CcRqCREATEGAMEWINDOW		:== 1900
///
// MW...
CcRqDO_PRINT_SETUP			:== 1828 // MW11++
CcRqDO_HTML_HELP			:==	1827

CcRqGET_PRINTER_DC			:== 1824
CcRqDISPATCH_MESSAGES_WHILE_PRINTING
							:== 1823
CcRqENDDOC					:== 1822
CcRqSTARTDOC				:== 1821
// ... MW
CcRqDESTROYMDIDOCWINDOW 	:== 1817		// PA: added to destroy MDI document window
CcRqCREATESDIDOCWINDOW		:==	1816		// PA: added to create SDI document window
CcRqCREATEMDIDOCWINDOW		:== 1815		// PA: added to create MDI document window
CcRqCREATEMDIFRAMEWINDOW	:== 1814		// PA: added to create MDI frame window
CcRqCREATESDIFRAMEWINDOW	:== 1813		// PA: added to create SDI frame window
CcRqCLIPBOARDHASTEXT		:== 1812
CcRqGETCLIPBOARDTEXT		:== 1811
CcRqSETCLIPBOARDTEXT		:== 1810
CcRqGETCLIPBOARDCOUNT		:== 1809		/* PA: added to retrieve clipboard count. */

CcRqDIRECTORYDIALOG			:==	1802		/* PA: added to create directory selector dialog. */
CcRqFILESAVEDIALOG			:== 1801
CcRqFILEOPENDIALOG			:== 1800

CcRqUPDATEDESKTOP			:== 1790		/* PA: added to force refresh of desktop. */

CcRqSHOWCONTROL				:== 1755		/* PA: added */
CcRqSELECTPOPUPITEM			:== 1754
CcRqENABLEPOPUPITEM			:== 1753
CcRqADDTOPOPUP				:== 1752
CcRqSETITEMCHECK			:== 1751
CcRqENABLECONTROL			:== 1750

CcRqCREATECOMPOUND			:== 1729		/* PA: added */
CcRqCREATESCROLLBAR			:== 1728		/* PA: added */
CcRqCREATECUSTOM			:== 1727
CcRqCREATEICONBUT			:== 1726
CcRqCREATEPOPUP				:== 1725
CcRqCREATECHECKBOX			:== 1724
CcRqCREATERADIOBUT			:== 1723
CcRqCREATEEDITTXT			:== 1722
CcRqCREATESTATICTXT			:== 1721
CcRqCREATEBUTTON			:== 1720

CcRqCREATEMODALDIALOG		:== 1701		/* PA: added to create modal dialog. */
CcRqCREATEDIALOG			:== 1700

CcRqCREATETOOLBARSEPARATOR	:==	1603		/* PA: added to create a toolbar separator item. */
CcRqCREATETOOLBARITEM		:== 1602		/* PA: added to create a toolbar bitmap item. */
CcRqCREATEMDITOOLBAR		:== 1601		/* PA: added to create a toolbar for a MDI process. */
CcRqCREATESDITOOLBAR		:==	1600		/* PA: added to create a toolbar. */

CcCbFONTSIZE				:== 1530

CcCbFONTNAME				:== 1520

CcRqGETFONTSIZES			:== 1510

CcRqGETFONTNAMES			:== 1500

CcRqSETCLIENTSIZE			:==	1438		/* PA: added to set client size. */
CcRqDELCONTROLTIP			:==	1437		/* PA: added to remove controls from tooltip areas. */
CcRqADDCONTROLTIP			:==	1436		/* PA: added to add controls to tooltip areas. */
CcRqGETWINDOWSIZE			:==	1435		/* PA: added to retrieve bounding size of windows. */
CcRqRESTACKWINDOW			:==	1434		/* PA: added to restack windows. */
CcRqSHOWWINDOW				:==	1433		/* PA: added to (hide/show) windows. */
CcRqSETWINDOWSIZE			:==	1432		/* PA: added to resize windows/controls. */
CcRqSETSELECTWINDOW			:== 1431		/* PA: added to (en/dis)able windows. */
CcRqSETWINDOWPOS			:== 1430		/* PA: added to move windows/controls. */

CcRqSETEDITSELECTION		:== 1428		/* PA: added for handling edit control selections. */
CcRqSETSCROLLSIZE			:==	1427		/* PA: added for setting thumb size of scrollbar. */
CcRqSETSCROLLPOS			:== 1426		/* PA: added for setting thumb of scrollbar. */
CcRqSETSCROLLRANGE			:== 1425		/* PA: added for setting range of scrollbar. */
CcRqRESETCURSOR				:== 1424
CcRqSETGLOBALCURSOR			:== 1423
CcRqOBSCURECURSOR			:== 1422
CcRqCHANGEWINDOWCURSOR		:== 1421
CcRqACTIVATEWINDOW			:==	1420		/* PA: added for activating window. */
CcRqACTIVATECONTROL			:== 1419		/* PA: added for activating controls. */

CcRqGETWINDOWPOS			:== 1416
CcRqGETCLIENTSIZE			:== 1415

CcRqUPDATEWINDOWRECT		:== 1412		/* PA: added for updating rect part of a window/control. */
CcRqGETWINDOWTEXT			:== 1411
CcRqSETWINDOWTITLE			:== 1410

CcRqENDPAINT				:== 1404
CcRqBEGINPAINT				:== 1403
CcRqDESTROYWINDOW			:== 1402
CcRqDESTROYMODALDIALOG		:==	1401		/* PA: added to destroy modal dialog. */

CcRqDRAWMBAR				:== 1265

CcRqTRACKPOPMENU			:==	1256		/* PA: added for handling pop up menu. */
CcRqCREATEPOPMENU			:== 1255

CcRqINSERTSEPARATOR			:== 1245

CcRqMENUENABLE				:== 1235

CcRqMODIFYMENU				:== 1230

CcRqINSERTMENU				:==	1226		// PA: new constant for inserting a new menu into the menu bar

CcRqITEMENABLE				:== 1220

CcRqREMOVEMENUSHORTKEY		:==	1217		// PA: new constant for removing a shortkey of a menu item
CcRqADDMENUSHORTKEY			:== 1216		// PA: new constant for adding a shortkey of a menu item
CcRqMODIFYMENUITEM			:== 1215
CcRqDESTROYMENU				:== 1214		// PA: new constant for destroying a menu 'physically'
CcRqDELETEMENU				:==	1213		// PA: new constant for deleting a menu logically
CcRqREMOVEMENUITEM			:== 1212

CcRqCHECKMENUITEM			:== 1210

CcRqINSERTMENUITEM			:== 1205

CcRqDOMESSAGE				:== 1100

  //------------------------------------------------------------------------//
 //  The message numbers for communication from OS to Clean (ccMsg field)  //
//------------------------------------------------------------------------//
CcWINMESSmax				:== 999

// Mike: Convention for OS to Clean requests: 500-599 //
CcWmCHECKQUIT				:== 513     /* Mike: check user's quit function */
CcWmUSEREVENT				:== 512     /* Mike: user defined event */
CcWmSTATISTICS				:== 511     /* Mike: request for statistics */
CcWmOBJECTKEYUP				:== 510     /* Mike: key released */
CcWmOBJECTKEYDOWN			:== 509     /* Mike: key pressed for object */
CcWmOBJECTTIMER				:== 508     /* Mike: framecounter reached 0 */
CcWmANIMATION				:== 507     /* Mike: animation sequence ended */
CcWmCOLLISION				:== 506     /* Mike: collision of two objects */
CcWmTOUCHBOUND				:== 505     /* Mike: object touches bound or code */
CcWmOBJECTDONE				:== 504     /* Mike: object is destroyed */
CcWmMOVEOBJECT				:== 503     /* Mike: move object */
CcWmINITOBJECT				:== 502     /* Mike: initialize new object */
CcWmSCROLL					:== 501     /* Mike: calculate layer position */
CcWmGAMEKEYBOARD			:== 500     /* Mike: keyboard input for game */
///
CcWmINETEVENT				:==	140		/* MW11 */

CcWmLOSTKEY					:== 135		/* PA: new constant for loosing keyboard input (generated only by Clean). */
CcWmLOSTMOUSE				:== 134		/* PA: new constant for loosing mouse input    (generated only by Clean). */
CcWmSPECIALBUTTON			:==	133		/* PA: new constant for info about OK/CANCEL button selected. */
CcWmPROCESSDROPFILES		:== 132		/* PA: new constant for requesting opening of files. */
CcWmGETTOOLBARTIPTEXT		:==	131		/* PA: new constant for getting tooltip text. */
CcWmSETFOCUS				:==	130		/* PA: new constant for notifying obtaining keyboard input focus. */
CcWmKILLFOCUS				:==	129		/* PA: new constant for notifying loss of keyboard input focus. */

CcWmPROCESSCLOSE			:==	127		/* PA: new constant for requesting closing of process. */
CcWmDRAWCLIPBOARD			:==	126		/* PA: new constant for clipboard handling. Copied from Ronny. */
CcWmGETSCROLLBARINFO		:==	125		/* PA: new constant for info about scrollbars. */
CcWmSCROLLBARACTION			:== 124		/* PA: new constant for scrollbar handling. */
CcWmDDEEXECUTE				:== 123

CcWmIDLEDIALOG				:== 121		/* PA: old constant reused for initialising modal dialogues. */
CcWmDRAWCONTROL				:== 120
CcWmCOMBOSELECT				:== 119
CcWmBUTTONCLICKED			:== 118
CcWmINITDIALOG				:== 117
CcWmIDLETIMER				:== 116
CcWmTIMER					:== 115
CcWmNEWVTHUMB				:== 114
CcWmNEWHTHUMB				:== 113
CcWmGETVSCROLLVAL			:== 112
CcWmGETHSCROLLVAL			:== 111
CcWmSIZE					:== 110		/* PA: old constant reused for passing resize information. */
CcWmMOUSE					:== 109
CcWmKEYBOARD				:== 108
CcWmDEACTIVATE				:== 107
CcWmACTIVATE				:== 106
CcWmCLOSE					:== 105
CcWmCOMMAND					:== 103
CcWmCHAR					:== 102
CcWmCREATE					:== 101
CcWmPAINT					:== 100

CcWINMESSmin				:== 100

CcWmNOTIFY					:== 78

CcRETURNmax					:== 19

CcRETURN6					:== 16
CcRETURN5					:== 15
CcRETURN4					:== 14
CcRETURN3					:== 13
CcRETURN2					:== 12
CcRETURN1					:== 11
CcRETURN0					:== 10

CcRETURNmin					:== 10

CcWASQUIT					:== 1
