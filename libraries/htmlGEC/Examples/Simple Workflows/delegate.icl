module delegate

import StdEnv, htmlTask


// (c) 2007 MJP

// Quite a difficult workflow exercise given to me by Erik Zuurbier.
// First a set of person id's is made to which a task can be delegated
// The task is actually shipped to the first person who accepts the task
// That person can stop the task whenever he wants
// Now again everybody in the set is asked again to accept the task
// The one who accepts can *continue* the work already done so far
// This process can be repeated as many times one likes until finally the task is finished

// When the timer goes, the whole process is repeated from scratch and the task performed so far is lossed.
// To make this work an additional combinator is needed. Work to do.

derive gForm [], Maybe
derive gUpd [], Maybe
derive gPrint Maybe

npersons = 5

Start world = doHtmlServer (multiUserTask npersons (delegate mytask2 (Time 0 15 0))) world

mytask = editTask "Done" 0
mytask2 =			editTask "Done1" 0
		 =>> \v1 ->	editTask "Done2" 0
		 =>> \v2 ->	editTask "Done3" 0
		 =>> \v3 -> returnDisplay (v1 + v2 + v3)

delegate :: (Task a) HtmlTime -> (Task a) | iData a
delegate taskToDelegate time 
=						[Txt "Choose persons you want to delegate work to:",Br,Br] 
						?>>	determineSet [] 
			=>> \set -> delegateToSet taskToDelegate set
			=>> \result -> returnDisplay result
where
	delegateToSet task set = newTask "delegateToSet" delegateToSet`
	where 
		delegateToSet`						
		  =									orTasks [("Waiting", who @:: editTask "I Will Do It" Void #>> returnV who) \\ who <- set]
			=>> \who 						->	who @:: (timedTask time task)	
			=>> \(stopped,TClosure task)	->	if stopped (delegateToSet task set) task 

	determineSet set = newTask "determineSet" determineSet`
	where
		determineSet`	
		= 					[Txt ("Current set:" +++ print set)] 
							?>> chooseTask	[("Add Person", cancelTask choosePerson =>> \nr  -> returnV nr)
											,("Finished",	returnV Nothing)
											]
			=>> \result -> case result of
							(Just new)  -> determineSet (sort (removeDup [new:set])) 
							Nothing		-> returnV set

		choosePerson =	editTask "Set" (PullDown (1,100) (0,[toString i \\ i <- [1..npersons]]))
						=>> \whomPD  -> returnV (Just (toInt(toString whomPD)))

		cancelTask task = orTask (task,editTask "Cancel" Void #>> returnV createDefault)
		
		print [] = ""
		print [x:xs] = toString x +++ " " +++ print xs

	timedTask :: HtmlTime (Task a) -> (Task (Bool,TClosure a)) | iCreateAndPrint a
	timedTask time task	= orTask  	( stopTask task
						 			, waitForTimerTask time #>> returnV (True,TClosure task)
						  			)
