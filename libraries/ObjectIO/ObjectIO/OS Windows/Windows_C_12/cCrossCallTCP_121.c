/********************************************************************************************
	Clean OS Windows library module version 1.2.1.
	This module is part of the Clean Object I/O library, version 1.2.1, 
	for the Windows platform.
********************************************************************************************/

/********************************************************************************************
	About this module:
	TCP event handling is done in the dedicated window class TCPWindowClassName instead of 
	the ghMainWindow in cCrossCall_121.c. The handle to this window  instance is ghTCPWindow.
	TCP events are sent by the routines in cTCP_121.c to ghMainWindow. The window procedure
	of ghMainWindow passes these events on to ghTCPWindow.
********************************************************************************************/
#include "cCrossCallTCP_121.h"
#include "cCrossCall_121.h"


//	Global data with external references:
DNSInfo *DNSInfoList = NULL;


/*	Registered Windows tcp window class name.
*/
static char TCPWindowClassName[]  = "__CleanTCPWindow";		/* Class for TCP child window of ghMainWindow.  */


/*	This function is used for looking up an element with a matching dnsHdl-field in
	the DNSInfoList. This element will then be removed from the list.
*/
static void lookUpAndRemove(WPARAM dnsHdl,DNSInfo **listPtr,DNSInfo **elPtr)
{
	if ((WPARAM)(*listPtr)->dnsHdl==dnsHdl)
		{	// the object to look up has been found, so remove it from the list
			// and give it back via elPtr.
			*elPtr = *listPtr;
			*listPtr = (*listPtr)->next;
		}
	  else
		lookUpAndRemove(dnsHdl, &(*listPtr)->next, elPtr);	
}


/*	The callback routine for a TCP window (extracted from MainWindowProcedure).
	It handles only PM_SOCKET_EVENT and PM_DNS_EVENT.
*/
static LRESULT CALLBACK TCPWindowProcedure (HWND hWin, UINT uMess, WPARAM wPara, LPARAM lPara)
{
	printMessage ("TCP Window", hWin, uMess, wPara, lPara);
	switch (uMess)
	{
		case PM_SOCKET_EVENT:
			{
				// wPara is the socket handle
				// LOWORD(lPara) is the message
				// HIWORD(lPara) is an error code
				switch (LOWORD(lPara))
				{	case FD_OOB:
					case FD_READ:	SendMessage3ToClean(CcWmINETEVENT,IE_RECEIVED, wPara,
														RChanReceiver);
									break;
					case FD_WRITE:	SendMessage3ToClean(CcWmINETEVENT,IE_SENDABLE, wPara,
														SChanReceiver);
									break;
					case FD_ACCEPT:	SendMessage3ToClean(CcWmINETEVENT,IE_CONNECTREQUEST, wPara,
														ListenerReceiver);
									break;
					case FD_CONNECT:SendMessage3ToClean(
										CcWmINETEVENT,
										HIWORD(lPara)==0 ?	IE_ASYNCCONNECTCOMPLETE :
															IE_ASYNCCONNECTFAILED,
										wPara,
										ConnectReceiver);
									break;
					case FD_CLOSE:	{
									dictitem	*pDictitem;
									pDictitem		= lookup(wPara);
									if (pDictitem) {
										if (pDictitem->hasReceiveNotifier)
											SendMessage3ToClean(CcWmINETEVENT,IE_EOM, wPara,
																RChanReceiver);
									
										if (pDictitem->hasSendableNotifier && HIWORD(lPara)!=0)
											SendMessage3ToClean(CcWmINETEVENT,IE_DISCONNECTED, wPara,
																SChanReceiver);
										};
									};
									break;
				};
				return 0;
			};
			break;
		case PM_DNS_EVENT:
			{ // wPara contains the DNS handle (the handle created by WSAAsyncGetHostByName
			  // The IP-adress of the looked up host will have been written into the
			  // corresponding element of the DNSInfoList. Look it up:

			  struct DNSInfo	*elPtr;
			  int				errCode;

			  errCode = HIWORD(lPara);

			  lookUpAndRemove(wPara,&DNSInfoList,&elPtr);
			  
			  // *elPtr contains the info

			  SendMessage4ToClean(	CcWmINETEVENT,
									errCode ?	IE_IPADDRESSNOTFOUND :
												IE_IPADDRESSFOUND,							
									elPtr->dnsHdl,
									DNSReceiver,
									errCode ?
										0 :
										ntohl(((int*)(*(elPtr->junion.Hostent.h_addr_list)))[0])
								 );

			  // deallocate unused memory
			  LocalFree(elPtr);
			  return 0;
			};
			break;
		default:
			return DefWindowProc (hWin, uMess, wPara, lPara);
			break;
	}
	return 0;
}	/*	TCPWindowProcedure */


/*	Register the TCPWindow class:
*/
void InitialiseCrossCallTCP (void)
{
	WNDCLASSEX wclass;

	/* register tcp window class */
	wclass.cbSize        = sizeof (WNDCLASSEX);
	wclass.style         = CS_NOCLOSE;
	wclass.lpfnWndProc   = (WNDPROC) TCPWindowProcedure;
	wclass.cbClsExtra    = 0;
	wclass.cbWndExtra    = 0;
	wclass.hInstance     = ghInst;
	wclass.hIcon         = LoadIcon (ghInst, IDI_APPLICATION);
	wclass.hCursor       = LoadCursor (ghInst, IDC_ARROW);
	wclass.hbrBackground = NULL;
	wclass.lpszMenuName  = NULL;
	wclass.lpszClassName = TCPWindowClassName;
	wclass.hIconSm       = NULL;
	RegisterClassEx (&wclass);
}


/*	Cross call procedure implementations.
	Eval<nr> corresponds with a CrossCallEntry generated by NewCrossCallEntry (nr,Eval<nr>).
*/
void EvalCcRqCREATETCPWINDOW (CrossCallInfo *pcci)		/* No cross call args; no result. */
{
	if (!ghTCPWindow)
		ghTCPWindow	= CreateWindow (TCPWindowClassName,		/* Class name					 */
									"",					 	/* Window title 				 */
									WS_POPUP,				/* style flags					 */
									0, 0,					/* x, y 						 */
									0, 0,					/* width, height 				 */
									NULL,					/* Parent window				 */
									(HMENU) NULL,			/* menu handle					 */
									(HANDLE) ghInst,		/* Instance that owns the window */
									0
								);
	MakeReturn0Cci (pcci);
}

int InstallCrossCallTCP (int ios)
{
	if (!ghTCPWindow)
	{
		CrossCallProcedureTable newTable;

		InitialiseCrossCallTCP ();

		newTable = EmptyCrossCallProcedureTable ();
		AddCrossCallEntry (newTable, CcRqCREATETCPWINDOW,EvalCcRqCREATETCPWINDOW);
		AddCrossCallEntries (gCrossCallProcedureTable, newTable);

		return ios;
	}
}