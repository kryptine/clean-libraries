/********************************************************************************************
	Clean OS Windows library module version 1.2.1.
	This module is part of the Clean Object I/O library, version 1.2.1,
	for the Windows platform.
********************************************************************************************/

/********************************************************************************************
	About this module:
	Routines related to clipboard handling.
********************************************************************************************/
#include "cCrossCallClipboard_121.h"
#include "cCrossCall_121.h"


/*	Cross call procedure implementations.
	Eval<nr> corresponds with a CrossCallEntry generated by NewCrossCallEntry (nr,Eval<nr>).
*/

void EvalCcRqCLIPBOARDHASTEXT (CrossCallInfo *pcci)		/* no arguments; bool result. */
{
    printf("EvalCcRqCLIPBOARDHASTEXT\n");
	MakeReturn1Cci (pcci,(int) gtk_clipboard_wait_is_text_available(gtk_clipboard_get(GDK_NONE)));
}

void EvalCcRqSETCLIPBOARDTEXT (CrossCallInfo *pcci)		/* textptr; no result. */
{
	const gchar *text = (const gchar *) pcci->p1;

    printf("EvalCcRqSETCLIPBOARDTEXT\n");
	gtk_clipboard_set_text (gtk_clipboard_get(GDK_NONE),
                            text, strlen(text));

	MakeReturn0Cci (pcci);
}

void EvalCcRqGETCLIPBOARDTEXT (CrossCallInfo *pcci)			/* no params; string result. */
{
	gchar *text = gtk_clipboard_wait_for_text(gtk_clipboard_get(GDK_NONE));
	char *result = g_strdup(text);
	g_free(text);

    printf("EvalCcRqGETCLIPBOARDTEXT\n");
	MakeReturn1Cci (pcci, (int) result);
}

/*	Install the cross call procedures in the gCrossCallProcedureTable of cCrossCall_121.
*/
OS InstallCrossCallClipboard (OS ios)
{
	CrossCallProcedureTable newTable;

    printf("InstallCrossCallClipboard\n");
	newTable = EmptyCrossCallProcedureTable ();
	AddCrossCallEntry (newTable, CcRqCLIPBOARDHASTEXT, EvalCcRqCLIPBOARDHASTEXT);
	AddCrossCallEntry (newTable, CcRqSETCLIPBOARDTEXT, EvalCcRqSETCLIPBOARDTEXT);
	AddCrossCallEntry (newTable, CcRqGETCLIPBOARDTEXT, EvalCcRqGETCLIPBOARDTEXT);
	AddCrossCallEntries (gCrossCallProcedureTable, newTable);

    return ios;
}
