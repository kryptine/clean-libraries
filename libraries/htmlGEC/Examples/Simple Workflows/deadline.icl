module deadline

import StdEnv, htmlTask, htmlTrivial

derive gForm []
derive gUpd  []

// (c) MJP 2007

// One can select a user to whom a task is delegated
// This user will get a certain amount of time to finish the task
// If the task is not finished on time, the task will be shipped back to the original user who has to do it instead
// It is also possible that the user becomes impatient and he can cancel the delegated task even though the deadline is not reached


npersons = 5

Start world = doHtmlServer (multiUserTask npersons (repeatTask (deadline mytask))) world

mytask = editTask "OK" 0 <| ((<) 23,\n -> "Error " <+++ n <+++ " should be larger than 23")

deadline :: (Task a) -> (Task a) |iData a
deadline task
=						[Txt "Choose person you want to delegate work to:",Br,Br] ?>>
						editTask "Set" (PullDown (1,100) (0,[toString i \\ i <- [1..npersons]])) =>> \whomPD ->	
						[Txt "How long do you want to wait?",Br,Br] ?>>
						editTask "SetTime" (Time 0 0 0) =>> \time ->
						[Txt "Cancel delegated work if you are getting impatient:",Br,Br] ?>>
						orTask
							(	delegateTask (toInt(toString whomPD)) time task
							, 	seqTask "Cancel" (return_V (False,createDefault))
							) =>> \(ok,value) ->
						if ok
							(	[Txt ("Result of task: " +++ printToString value),Br,Br] ?>>
								seqTask "OK" (return_V value)
							)
							(	[Txt "Task expired or canceled, you have to do it yourself!",Br,Br] ?>>
								seqTask "OK" task
							)
where
	delegateTask who time task
	= 	(who,"Timed Task") 	
		@:orTask	
			(	waitForTimerTask time #>> 								// wait for deadline
				return_V (False,createDefault)							// return default value
			, 	[Txt ("Please finish task before" <+++ time),Br,Br] ?>>	// tell deadline
				(task =>> \v -> return_V (True,v))						// do task and return its result
			) 
