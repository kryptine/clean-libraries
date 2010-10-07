/********************************************************************************************
	Clean OS Windows library module version 1.2.1.
	This module is part of the Clean Object I/O library, version 1.2.1,
	for the Windows platform.
********************************************************************************************/

/********************************************************************************************
	About this module:
	Routines related to printer handling.
********************************************************************************************/

#include "cCrossCallPrinter_121.h"

#if 0

#include "cCrossCall_121.h"
#include "cprinter_121.h"

extern BOOL bUserAbort;
extern HWND hDlgPrint;		/* MW: hDlgPrint is the handle of the "Cancel Printing" dialog. */
extern HWND hwndText;		/* MW: hwndText  is the handle of the page count text in the dialog. */


/*	Cross call procedure implementations.
	Eval<nr> corresponds with a CrossCallEntry generated by NewCrossCallEntry (nr,Eval<nr>).
*/
void EvalCcRqDO_PRINT_SETUP (CrossCallInfo *pcci)
{	int ok;
	PRINTDLG *pdPtr;
	printSetup(0, pcci->p1,
				(char*) pcci->p2, (char*) pcci->p3, (char*) pcci->p4, (char*) pcci->p5,
				&ok, &pdPtr);
	MakeReturn2Cci (pcci, ok, (int) pdPtr);
}

void EvalCcRqGET_PRINTER_DC (CrossCallInfo *pcci)
{	int doDialog,emulateScreenRes,
		err,first,last,copies,pPrintDlg,deviceContext;

	// unpack doDialog and emulateScreenRes
	doDialog			= (pcci->p1) & 1;
	emulateScreenRes	= (pcci->p1) & 2;

	getDC(	doDialog,emulateScreenRes,FALSE,pcci->p2,
			(char*) pcci->p3,(char*) pcci->p4,(char*) pcci->p5,(char*) pcci->p6,
			&err,&first,&last,&copies,(PRINTDLG**)&pPrintDlg,&deviceContext);
	MakeReturn6Cci (pcci,err,first,last,copies,pPrintDlg,deviceContext);
}

void EvalCcRqSTARTDOC (CrossCallInfo *pcci)
{
	HDC hdc = (HDC) pcci->p1;
	int err;

	EnableWindow (ghMainWindow, FALSE) ;
	hDlgPrint = CreateCancelDialog ();
	SetAbortProc (hdc, AbortProc) ;
	err = startDoc((int) hdc);
	if (err<=0 && ghMainWindow!=NULL && !bUserAbort)
	{
		EnableWindow (ghMainWindow, TRUE) ;
		DestroyWindow (hDlgPrint) ;
	};
	MakeReturn1Cci (pcci,err);
}

void EvalCcRqENDDOC (CrossCallInfo *pcci)
{
	HDC hdc = (HDC) pcci->p1;

	endDoc((int) hdc);
	if (ghMainWindow!=NULL && !bUserAbort)
	{
		EnableWindow (ghMainWindow, TRUE) ;
		DestroyWindow (hDlgPrint) ;
	};
	MakeReturn0Cci (pcci);
}

void EvalCcRqDISPATCH_MESSAGES_WHILE_PRINTING (CrossCallInfo *pcci)
{
	MSG   msg ;
	char *pageMessage= (char *) (pcci->p1);

	SetWindowText(hwndText,pageMessage);

	while (!bUserAbort && PeekMessage (&msg, NULL, 0, 0, PM_REMOVE))
	{
		if (!hDlgPrint || !IsDialogMessage (hDlgPrint, &msg))
		{
			TranslateMessage (&msg) ;
			DispatchMessage (&msg) ;
		}
	}
	MakeReturn0Cci (pcci);
}


/*	Install the cross call procedures in the gCrossCallProcedureTable of cCrossCall_121.
*/
void InstallCrossCallPrinter ()
{
	CrossCallProcedureTable newTable;

	newTable = EmptyCrossCallProcedureTable ();
	AddCrossCallEntry (newTable, CcRqDO_PRINT_SETUP,                   EvalCcRqDO_PRINT_SETUP);
	AddCrossCallEntry (newTable, CcRqGET_PRINTER_DC,                   EvalCcRqGET_PRINTER_DC);
	AddCrossCallEntry (newTable, CcRqSTARTDOC,                         EvalCcRqSTARTDOC);
	AddCrossCallEntry (newTable, CcRqENDDOC,                           EvalCcRqENDDOC);
	AddCrossCallEntry (newTable, CcRqDISPATCH_MESSAGES_WHILE_PRINTING, EvalCcRqDISPATCH_MESSAGES_WHILE_PRINTING);
	AddCrossCallEntries (gCrossCallProcedureTable, newTable);
}

#else

OS InstallCrossCallPrinter (OS ios)
{
        return ios;
}

#endif
