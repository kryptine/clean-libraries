definition module iDataState

// maintains the state of the iDate
// (c) 2005 - MJP

import GenParse, GenPrint
import htmlDataDef, EncodeDecode

// Maintaining the internal state of all forms

:: *FormStates 													// collection of all states of all forms

emptyFormStates		:: *FormStates								// creates empty states

findState 			:: !(FormId a) !*FormStates *NWorld			// find the state value given FormId and a correct type
					-> (Bool, Maybe a,*FormStates,*NWorld)		// true if form has not yet been previously inspected 	
												| iDataSerAndDeSerialize a		
replaceState 		:: !(FormId a) a !*FormStates *NWorld 		// replace state given FormId
					-> (*FormStates,*NWorld)	| iDataSerialize a

getUpdateId 		:: !*FormStates -> (String,!*FormStates)	// id of previously changed form
getUpdate 			:: !*FormStates -> (String,!*FormStates)	// value typed in by user as string

// storage and retrieval of FormStates

retrieveFormStates 	:: ServerKind (Maybe String) *NWorld -> (*FormStates,*NWorld) 	// retrieves all form states hidden in the html page
storeFormStates 	:: !FormStates *NWorld -> (BodyTag,*NWorld)


getTriplet  		:: !*FormStates -> (!Maybe Triplet,!Maybe b,!*FormStates)  | gParse{|*|} b // inspect triplet


// tracing all states ...

traceStates :: !*FormStates -> (BodyTag,!*FormStates)

// fstate handling used for testing only

initTestFormStates 	::  *NWorld -> (*FormStates,*NWorld) 		// creates initial empty form states
setTestFormStates 	:: [(Triplet,String)] String String *FormStates *NWorld -> (*FormStates,*NWorld)			// retrieves all form states hidden in the html page
