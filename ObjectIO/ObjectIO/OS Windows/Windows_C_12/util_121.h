#ifndef _UTILH
#define _UTILH

#define STRICT
#include <windows.h>
#include <shlobj.h>


#define SIGNEDLOWORD(i)  ((short) i)
#define SIGNEDHIWORD(i)  ((short) ((i)>>16))


/*  OS type, threading all calls from Clean.
*/

typedef int OS;
typedef int Bool; 
typedef int HITEM; 

typedef struct 
{   int  mess;
    int  p1;
    int  p2;
    int  p3;
    int  p4;
    int  p5;
    int  p6;
} CrossCallInfo;

typedef struct clean_string
    {   int  length;
        char characters[1];
    } *CLEAN_STRING;


#include "intrface_121.h"

extern void SetLogFontData (LOGFONT*, char*, int, int);

/*  since we don't use the C runtime library, here are some simple
    routines that would normally come from the C runtime lib.
*/
// PA: extern added
extern void rfree( HGLOBAL ptr );
extern HGLOBAL rmalloc( DWORD bytes );

extern int rstrlen(char *s);
extern void rsncopy(char *d, const char *s, int n);
extern void rscopy(char *d, const char *s);
extern BOOL strequal( char *s1, char *s2 );
extern BOOL nstrequal( int length, char *s1, char *s2 );
extern int rabs(int i);

/*  clean_strings don't have to end with 0, so we have to make
    copy the clean string and end it with a 0.
    global variables used for conversion from c strings to clean strings
*/

extern char *cstring (CLEAN_STRING s);
extern CLEAN_STRING cleanstring (char *s);
// PA: up to here

extern OS WinReleaseCString (PSTR,OS);
extern void WinGetCString (PSTR,OS,CLEAN_STRING*,OS*);
extern void WinGetCStringAndFree (PSTR,OS,CLEAN_STRING*,OS*);
extern void WinMakeCString (CLEAN_STRING,OS,PSTR*,OS*);

//	PA: extern added to the end
extern int nCopyAnsiToWideChar (LPWORD, LPSTR);

/*  The following routines are used to write to the console, or convey runtime errors
    with message boxes. 
*/

#ifndef _RPRINTBUFSIZE
#define _RPRINTBUFSIZE 512
#endif

extern void rMessageBox(HWND owner, UINT style, char *title, char *format, ... );
extern void CheckF(BOOL theCheck, char *checkText, char *checkMess, char *filename, int linenum);
extern void ErrorExit(char *format, ...);
extern char *BOOLstring( BOOL b );

#define Check(check,mess) CheckF((check),(#check),(mess),__FILE__,__LINE__)

extern void DumpMem( int *ptr, int lines);

/* #define LOGFILE "debuglog.txt" */
# undef LOGFILE

#ifdef LOGFILE
extern void rprintf(char *format, ... );
extern void printCCI( CrossCallInfo *pcci );
extern void printMessage( char* fname, HWND hWin, UINT uMess, WPARAM wPara, LPARAM lPara);
#else
# define rprintf /* RWS() */
# define printCCI(a1)
# define printMessage(a1,a2,a3,a4,a5)
#endif

#endif
