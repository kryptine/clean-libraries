definition module htmlEncodeDecode

// maintains the state of forms
// internally (in a tree containing the state of all forms),
// and externally, either in a html form or in files on disk.
// provides the encoding and decoding of information between browser and myprogram.exe via myprogram.php
// (c) 2005 - MJP

import StdMaybe
import GenParse, GenPrint
import htmlDataDef, htmlFormData

// constants that maybe useful

:: ServerKind
	= External		// An external Server has call to this executable (currently via a PhP script)
	| JustTesting	// No Server attached at all, intended for testing (in collaboration with Gast)
	| Internal		// No external server needed: a Clean Server will be atached to this executable
	

ThisExe			:: ServerKind -> String		// name of this executable
MyPhP 			:: ServerKind -> String		// name of php script interface between server and this executable
MyDir 			:: ServerKind -> String		// name of directory in which persistent form info is stored

traceHtmlInput	:: ServerKind (Maybe String) -> BodyTag	// for debugging showing the information received from browser

// Decoding of information

:: *FormStates 					// collection of all states of all forms

emptyFormStates :: *FormStates								// creates emtpy states
initFormStates 	:: ServerKind (Maybe String) *NWorld -> (*FormStates,*NWorld) 		// retrieves all form states wherever they are stored

findState 		:: !FormId *FormStates *NWorld 				// find the state value given FormId and a correct type
					-> (Bool, Maybe a,*FormStates,*NWorld)	// true if form has not yet been previously inspected 	
												| gParse{|*|} a & TC a		
replaceState 	:: !FormId a *FormStates *NWorld 			// replace state given FormId
					-> (*FormStates,*NWorld)	| gPrint{|*|} a & TC a

getTriplet  	:: *FormStates -> (!Maybe a, !Maybe b,*FormStates) // triplet, value of changed part
												| gParse{|*|} a & gParse{|*|} b 
getUpdateId 	:: *FormStates -> (String,*FormStates)		// id of previously changed form
getUpdate 		:: *FormStates -> (String,*FormStates)		// value typed in by user as string

convStates 		:: !FormStates *NWorld -> (BodyTag,*NWorld) // script which stores the global state for the next round


// low level encoding of information

encodeInfo 		:: a -> String | gPrint{|*|} a	// serialization to a Mime format, used to encode input forms 
callClean 		:: Script						// script that will take care of sending the required input to this application


urlDecode :: [Char] -> [Char]

// for testing

initTestFormStates 	::  *NWorld -> (*FormStates,*NWorld) // creates initial empty form states

