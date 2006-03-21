definition module stateHandling

import loginAdmin, htmlFormlib

// The Information to maintain:

:: ConfAccounts	:== [ConfAccount]
:: ConfAccount	:== Account Member

// Shared Information:

:: RefPerson	=	RefPerson   (Refto Person)
:: RefPaper		=	RefPaper 	(Refto Paper)	
:: RefReport	=	RefReport	(Refto Report)

// Information maintained by the Conference Manager

:: Member 		= 	ConfManager		ManagerInfo			
				|	Authors			PaperInfo							
				| 	Referee 		RefereeInfo
:: ManagerInfo	=	{ person		:: RefPerson
					}
:: PaperInfo	=	{ person		:: RefPerson
					, nr			:: PaperNr
					, paper			:: RefPaper
					}
:: RefereeInfo	=	{ person		:: RefPerson  
					, conflicts		:: Conflicts 
					, reports		:: Reports
					} 
:: PaperNr 		:==	Int
:: Conflicts	=	Conflicts 		[PaperNr]
 
// Information maintained by a referee

:: Reports		=	Reports			[(PaperNr, Maybe RefReport)]
:: Report		=	{ recommendation:: Recommendation
					, familiarity 	:: Familiarity 
					, commCommittee	:: CommCommittee
					, commAuthors	:: CommAuthors
					}
:: Recommendation 
				= 	StrongAccept
				| 	Accept
				| 	WeakAccept
				| 	WeakReject
				| 	Reject
				| 	StrongReject
:: Familiarity	= 	Expert
				| 	Knowledgeable
				| 	Low
:: CommCommittee:== String // TextArea 
:: CommAuthors	:==	String // TextArea 

// Information maintained by the Conference Manager *or* a Referee *or* an Author

:: Person 		=	{ firstName 	:: String
					, lastName		:: String
					, affiliation	:: String
					, emailAddress	:: String
					} 

// Information submitted by an author

:: Paper		=	{ title			:: String
					, first_author	:: Person
					, co_authors	:: Co_authors
					, abstract		:: String
					, pdf			:: String
					}
:: Co_authors 	=	Co_authors [Person]					

// access functions on these data structures:

initManagerLogin 	:: Login
initManagerAccount 	:: Login 		-> ConfAccount

isConfManager 		:: ConfAccount	-> Bool

getRefPerson 		:: Member 		-> RefPerson
getRefPapers 		:: ConfAccounts -> [(Int,RefPaper)]

// invariants testing and setting

invariantPerson 		:: Person -> Judgement
setInvariantAccounts 	:: ConfAccounts -> ConfAccounts


/*

initRefereeAccount 	:: Login 		-> ConfAccount
initAuthorsAccount	:: Login Int 	-> ConfAccount

initReport 			:: Report
initPaper 			:: String -> Paper

setInvariantAccounts:: ConfAccounts -> ConfAccounts

findReports 		:: Int [ConfAccount] -> [(Person,Maybe Report)]
findReport 			:: Int ConfAccount -> (Maybe Report)
getReports 			:: Reports -> [(PaperNr, Maybe Report)]
addReport 			:: Int (Maybe Report) ConfAccount -> ConfAccount
emptyReport 		:: Report

assignPaper 		:: Int ConfAccount -> ConfAccount
deletePaper 		:: Int ConfAccount -> ConfAccount
isRefereeOf 		:: Int ConfAccount -> Bool
hasRefereed 		:: Int ConfAccount -> Bool
papersToReferee 	:: ConfAccount -> [PaperNr]
papersRefereed 		:: ConfAccount -> [PaperNr]
papersNotRefereed 	:: ConfAccount -> [PaperNr]

assignConflict 		:: Int ConfAccount -> ConfAccount
deleteConflict		:: Int ConfAccount -> ConfAccount
isConflict	 		:: Int ConfAccount -> Bool

findPaper 			:: Int Papers -> (Maybe Paper)

invariantConvDB 	:: ConfAccounts -> (Bool,String)
*/