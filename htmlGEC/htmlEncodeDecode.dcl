definition module htmlEncodeDecode

// encoding and decoding of information
// (c) 2005 - MJP

import StdMaybe
import GenParse, GenPrint, htmlDataDef

// constants that maybe useful

ThisExe			:: String		// name of this executable
MyPhP 			:: String		// name of php script interface between server and this executable

traceHtmlInput	:: Body			// for debugging to show which information is received from browser

// encoding of information

:: GlobalState :== [(String,String)]

encodeInfo 		:: a -> String | gPrint{|*|} a	// format required for storing stuf in html
callClean 		:: String						// call script that will transmit input info to this executable
addScript 		:: GlobalState -> Body			// the corresponding script, stores global state as well					

// decoding of information

CheckUpdateId 	:: String
CheckUpdate 	:: (Maybe a, Maybe b) | gParse{|*|} a & gParse{|*|} b 
CheckGlobalState :: String
ShiftState 		:: String -> (Maybe (String,a),String) | gParse{|*|} a 
