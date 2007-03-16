implementation module htmlTask

// (c) MJP 2006 - 2007

import StdEnv, StdHtml

derive gForm 	[], Void
derive gUpd 	[], Void
derive gParse 	Void
derive gPrint 	Void
derive gerda 	Void

:: *TSt 		=	{ tasknr 		:: ![Int]			// for generating unique form-id's
					, activated		:: !Bool   			// if true activate task, if set as result task completed	
					, myId			:: !Int				// id of user to which task is assigned
					, userId		:: !Int				// id of application user 
					, html			:: !HtmlTree		// accumulator for html code
					, storageInfo	:: !Storage			// iData lifespan and storage format
					, trace			:: !Maybe [Trace]	// for displaying task trace
					, hst			:: !HSt				// iData state
					}

:: HtmlTree		=	BT [BodyTag]						// simple code
				|	(@@:) infix  0 (Int,String) HtmlTree// code with id of user attached to it
				|	(-@:) infix  0 Int 			HtmlTree// skip code with this id if it is the id of the user 
				|	(+-+) infixl 1 HtmlTree HtmlTree	// code to be placed next to each other				
				|	(+|+) infixl 1 HtmlTree HtmlTree	// code to be placed below each other				

:: Storage		=	{ tasklife		:: !Lifespan		
					, taskstorage	:: !StorageFormat
					, taskmode		:: !Mode
					}

:: Trace		=	Trace TraceInfo [Trace]				// traceinfo with possibly subprocess

:: TraceInfo	:== Maybe (Bool,(Int,[Int],String,String))	// Task finished? who did it, task nr, task name (for tracing) value produced

// setting global iData options for tasks

instance setTaskAttr Lifespan
where setTaskAttr lifespan tst = {tst & storageInfo.tasklife = lifespan}

instance setTaskAttr StorageFormat
where setTaskAttr storageformat tst = {tst & storageInfo.taskstorage = storageformat}

instance setTaskAttr Mode
where setTaskAttr mode tst = {tst & storageInfo.taskmode = mode}

// wrappers

singleUserTask :: !(Task a) !*HSt -> (Html,*HSt) | iCreate a 
singleUserTask task hst 
# (_,html,hst) = startTask 0 task hst
= mkHtml "stest" html hst

multiUserTask :: !Int!(Task a) !*HSt -> (Html,*HSt) | iCreate a 
multiUserTask nusers task  hst 
# (idform,hst) 	= FuncMenu (Init,nFormId "User_Selected" 
						(0,[("User " +++ toString i,\_ -> i) \\ i<-[0..nusers - 1] ])) hst
# currentWorker	= snd idform.value
# (_,html,hst) 	= startTask currentWorker task hst
= mkHtml "mtest" (idform.form ++ html) hst

startTask :: !Int !(Task a) !*HSt -> (a,[BodyTag],!*HSt) | iCreate a 
startTask thisUser taska hst
# userVersionNr			= "User" <+++ thisUser <+++ "_VersionPNr"
# sessionVersionNr		= "User" <+++ thisUser <+++ "_VersionSNr" 
# traceId				= "User" <+++ thisUser <+++ "_Trace" 
# (pversion,hst)	 	= mkStoreForm (Init, pFormId userVersionNr 0) id hst
# (refresh,hst) 		= simpleButton userVersionNr "Refresh" id hst
# (traceAsked,hst) 		= simpleButton traceId "ShowTrace" (\_ -> True) hst
# doTrace				= traceAsked.value False
# (sversion,hst)	 	= mkStoreForm (Init, nFormId sessionVersionNr pversion.value) (if refresh.changed (\_ -> pversion.value) id) hst
| sversion.value < pversion.value	= (createDefault,  refresh.form ++ [Br,Br, Hr [],Br] <|.|>
														[Font [Fnt_Color (`Colorname Yellow)]
													   [B [] "Sorry, cannot apply command.",Br, 
													    B [] "Your page is not up-to date!",Br]],hst)
# (a,{html,hst,trace}) = taska 	{ tasknr	= [-1]
								, activated = True
								, userId	= thisUser 
								, myId		= defaultUser 
								, html 		= BT []
								, trace		= if doTrace (Just []) Nothing
								, hst 		= hst
								, storageInfo = {tasklife = Session, taskstorage = PlainString, taskmode = Edit }}
# (pversion,hst)	 	= mkStoreForm (Init, pFormId userVersionNr 0) inc hst
# (sversion,hst)	 	= mkStoreForm (Init, nFormId sessionVersionNr pversion.value) inc hst
# (selbuts,selname,seltask,hst)	= Filter thisUser defaultUser ((defaultUser,"Main") @@: html) hst
= 	(a,	refresh.form ++ traceAsked.form ++
		[Br,Hr [],showUser thisUser,Br,Br] ++ 
		if doTrace
			[ printTrace2 trace ]
			[ STable []	[ [BodyTag  selbuts, selname <||>  seltask ]
						]
			] 
	,hst)
where
	defaultUser	= 0

	mkSTable2 :: [[BodyTag]] -> BodyTag
	mkSTable2 table
	= Table []	(mktable table)
	where
		mktable table 	= [Tr [] (mkrow rows) \\ rows <- table]	
		mkrow rows 		= [Td [Td_VAlign Alo_Top] [row] \\ row <- rows] 
	
	Filter id user tree hst
	# (_,accu) 		= Collect ((==) id) user [] tree
	| isNil accu	= ([],[],[],hst)
	# (names,tasks) = unzip accu
	# info			= { tasklife = Session, taskstorage	= PlainString, taskmode = Edit}
	# (selected,buttons,chosenname,hst) = mkTaskButtons "Main Tasks:" ("User" <+++ id) [] info names hst 
	= (buttons,chosenname,tasks!!if (selected >= length accu) 0 selected,hst)

	Collect pred user accu ((nuser,taskname) @@: tree)
	# (myhtml,accu)	= Collect pred nuser accu tree
	| pred nuser && not (isNil myhtml)
					= ([],[(taskname,myhtml):accu])
	| otherwise		= ([],accu)
	Collect pred user accu (BT bdtg)
	| pred user		= (bdtg,accu)
	| otherwise		= ([],accu)
	Collect pred user accu  (tree1 +|+ tree2)
	# (lhtml,accu)	= Collect pred user accu tree1
	# (rhtml,accu)	= Collect pred user accu tree2
	= (lhtml <|.|> rhtml,accu)
	Collect pred user accu  (tree1 +-+ tree2)
	# (lhtml,accu)	= Collect pred user accu tree1
	# (rhtml,accu)	= Collect pred user [] tree2
	= ([lhtml <=> rhtml],accu)
	Collect pred user accu (nuser -@: tree)
					= Collect (\v -> pred v && ((<>) nuser v)) user accu tree
//					= Collect (\v -> (<>) nuser v) user accu tree

	isNil [] = True
	isNil _ = False

mkTaskButtons :: !String !String ![Int] !Storage ![String] *HSt -> (Int,[BodyTag],[BodyTag],*HSt)
mkTaskButtons header myid tasknr info btnnames hst
# btnsId			= itaskId tasknr (myid <+++ "_Btns")
# myidx				= length btnnames
# (chosen,hst)		= SelectStore (myid,myidx) tasknr info id hst					// which choice was made in the past
# (buttons,hst)		= SelectButtons Init btnsId info (chosen,btnnames) hst				// create buttons
# (chosen,hst)		= SelectStore (myid,myidx) tasknr info  buttons.value hst		// maybe a new button was pressed
# (buttons,hst)		= SelectButtons Set btnsId info (chosen,btnnames) hst				// adjust look of that button
= (chosen,[red header, Br: buttons.form],[yellow (btnnames!!chosen),Br,Br],hst)
where
	SelectButtons init id info (idx,btnnames) hst = TableFuncBut2 (init,cFormId info id 
															[[(mode idx n, but txt,\_ -> n)] \\ txt <- btnnames & n <- [0..]] <@ Page) hst
	but i = LButton defpixel i

	mode i j
	| i==j = Display
	= Edit

	SelectStore :: !(String,Int) ![Int] !Storage (Int -> Int) *HSt -> (Int,*HSt)
	SelectStore (myid,idx) tasknr info fun hst 
	# storeId 			= itaskId tasknr (myid <+++ "_Select" <+++ idx)
	# (storeform,hst)	= mkStoreForm (Init,cFormId info storeId 0) fun hst
	= (storeform.value,hst)


// make an iTask editor

editTask :: String a -> (Task a) | iData a 
editTask prompt a = mkTask "editTask" (editTask` prompt a)

editTask` prompt a tst=:{tasknr,html,hst}
# taskId			= itaskId tasknr "_Seq"
# editId			= itaskId tasknr "_Val"
# buttonId			= itaskId tasknr "_But"
# (taskdone,hst) 	= mkStoreForm (Init,cFormId tst.storageInfo taskId False) id hst  			// remember if the task has been done
| taskdone.value																				// test if task has completed
	# (editor,hst) 	= (mkEditForm  (Init,cdFormId tst.storageInfo editId a <@ Display) hst)		// yes, read out current value, make editor passive
	= (editor.value,{tst & activated = True, html = html +|+ BT editor.form, hst = hst})		// return result task
# (editor,hst) 		= mkEditForm  (Init,cFormId tst.storageInfo editId a) hst					// no, read out current value from active editor
# (finbut,hst)  	= simpleButton buttonId prompt (\_ -> True) hst								// add button for marking task as done
# (taskdone,hst) 	= mkStoreForm (Init,cFormId tst.storageInfo taskId False) finbut.value hst 	// remember task status for next time
| taskdone.value	= editTask` prompt a {tst & hst = hst}										// task is now completed, handle as previously
= (editor.value,{tst & activated = taskdone.value, html = html +|+ BT (editor.form ++ finbut.form), hst = hst})

// monads for combining itasks

(=>>) infix 1 :: (Task a) (a -> Task b) -> Task b
(=>>) a b = a `bind` b

(#>>) infixl 1 :: (Task a) (Task b) -> Task b
(#>>) a b = a `bind` (\_ -> b)

return_V :: a -> (Task a) | iCreateAndPrint a
return_V a  = mkTask "return_V" (return a) 

ireturn_V :: a -> (Task a) 	// for internal use, not shown in trace...
ireturn_V a  = return a	

return_D :: a -> (Task a) | gForm {|*|}, iCreateAndPrint a
return_D a = mkTask "return_D" return_Display`
where
	return_Display` tst
	= (a,{tst & html = tst.html +|+ BT [toHtml a ]})		// return result task

return_VF :: a [BodyTag] -> (Task a) | iCreateAndPrint a
return_VF a bodytag = mkTask "return_VF" return_VF`
where
	return_VF` tst
	= (a,{tst & html = tst.html +|+ BT bodytag})

(<|) infix 3 :: (Task a) (a -> .Bool, a -> String) -> Task a | iCreate a
(<|) taska (pred,message) = doTask
where
	doTask tst=:{html = ohtml,activated}
	| not activated 			= (createDefault,tst)
	# (a,tst=:{activated,html= nhtml}) = taska {tst & html = BT []}
	| not activated || pred a	= (a,{tst & html = ohtml +|+ nhtml})
	= doTask {tst & html = ohtml +|+ BT [Txt (message a)]}

(<<@) infix 3 ::  (Task a) b  -> (Task a) | setTaskAttr b
(<<@) task attr = doTask
where
	doTask tst=:{storageInfo}
	# tst = setTaskAttr attr tst
	# (a,tst) = task (setTaskAttr attr tst)
	= (a,{tst & storageInfo = storageInfo})

(?>>) infix 2 :: [BodyTag] (Task a) -> (Task a)
(?>>) prompt task = doTask
where
	doTask tst=:{html=ohtml,activated=myturn}
	# (a,tst=:{activated,html=nhtml}) = task {tst & html = BT []}
	| activated || not myturn= (a,{tst & html = ohtml})
	= (a,{tst & html = ohtml +|+ BT prompt +|+ nhtml})

(!>>) infix 2 :: [BodyTag] (Task a) -> (Task a) | iCreate a
(!>>) prompt task = doTask
where
	doTask tst=:{html=ohtml,activated=myturn}
	| not myturn	= (createDefault,tst)
	# (a,tst=:{activated,html=nhtml}) = task {tst & html = BT []}
	= (a,{tst & html = ohtml +|+ BT prompt +|+ nhtml})

// Task makers are wrappers which take care of
//		- deciding whether a task should be called (activated) or not
//		- adding trace information
//		- generating task numbers in a systematic way
// It is very important that the numbering of the tasks is done systematically
// Every task should have a unique number
// Every sequential task should increase the task number
// If a task j is a subtask of task i, than it will get number i.j in reverse order
	
mkTask :: !String (Task a) -> (Task a) | iCreateAndPrint a
mkTask taskname mytask = mkTaskNoInc taskname mytask o incTaskNr

mkTaskNoInc :: !String (Task a) -> (Task a) | iCreateAndPrint a			// common second part of task wrappers
mkTaskNoInc taskname mytask = mkTaskNoInc`
where
	mkTaskNoInc` tst=:{activated,tasknr,myId}		
	| not activated							= (createDefault,tst)	// not active, don't call task, return default value
	# (val,tst=:{activated,trace})			= mytask tst			// active, so perform task and get its result
	| isNothing trace || taskname == ""		= (val,tst)				// no trace, just return value
	= (val,{tst & tasknr = tasknr
				, trace = Just (InsertTrace activated tasknr myId taskname (printToString val) (fromJust trace))}) // adjust trace

incTaskNr tst 		= {tst & tasknr = incNr tst.tasknr}
newSubTaskNr tst	= {tst & tasknr = [-1:tst.tasknr]}

incNr [] = [0]
incNr [i:is] = [i+1:is]

addTasknr [] j = [j]
addTasknr [i:is] j = [i+j:is]

// non optimized versions of repeattask and newTask will increase the task tree stack and
// therefore cannot be used for big applications

repeatTask_Std :: (Task a) -> Task a | iCreateAndPrint a
repeatTask_Std task = mkTask "repeatTask_Std" dorepeatTask_Std
where
	dorepeatTask_Std tst		
	# (_,tst)	= task (newSubTaskNr tst)		
	= repeatTask_Std task tst						

newTask_Std :: !String (Task a) -> (Task a) | iCreateAndPrint a
newTask_Std taskname mytask = mkTask taskname (mytask o newSubTaskNr)

// same, but by remembering task results stack space can be saved

repeatTask :: (Task a) -> Task a | iData a
repeatTask task = repeatTask`
where
	repeatTask` tst=:{tasknr,hst} 
	# mytasknr					= incNr tasknr							// manual incr task nr
	# taskId					= itaskId mytasknr "_Rep"				// create store id
	# (currtasknr,hst)			= mkStoreForm (Init,cFormId tst.storageInfo taskId mytasknr) id hst	// fetch actual tasknr
	# (val,tst=:{activated,hst})= mkTaskNoInc "repeatTask" repeatTask`` {tst & tasknr = currtasknr.value,hst = hst}
	| activated 																					// task is completed	
		# ntasknr				= incNr currtasknr.value											// incr tasknr
		# (currtasknr,hst)		= mkStoreForm (Init,cFormId tst.storageInfo taskId tasknr) (\_ -> ntasknr) hst // store next task nr
		= mkTaskNoInc "repeatTask" repeatTask`` {tst & tasknr = currtasknr.value, hst = hst}		// initialize new task
	= (val,tst)					
	where
		repeatTask`` tst=:{tasknr}		
		# (val,tst)= task {tst & tasknr = [-1:tasknr]}	// do task to repeat
		= (val,{tst & tasknr = tasknr})					

newTask :: !String (Task a) -> (Task a) 	| iData a 
newTask taskname mytask = mkTask taskname (newTask` False mytask)

newTask` collect mytask tst=:{tasknr,hst}		
# taskId					= itaskId tasknr "_New"
# (taskval,hst) 			= mkStoreForm (Init,cFormId tst.storageInfo taskId (False,createDefault)) id hst  // remember if the task has been done
# (taskdone,taskvalue)		= taskval.value
| taskdone					= (taskvalue,{tst & hst = hst})					// optimize: return stored value
# (val,tst=:{activated,hst})= mytask {tst & tasknr = [-1:tasknr],hst =hst} 	// do task, first shift tasknr
| not activated				= (val,{tst & tasknr = tasknr})					// subtask not ready, return value of subtasks
# tst=:{hst}				= if collect 
									(deleteSubTasks [0:tasknr] {tst & tasknr = [0:tasknr]})
									tst
# (_,hst) 					= mkStoreForm (Init,cFormId tst.storageInfo taskId (False,createDefault)) (\_ -> (True,val)) hst  // remember if the task has been done
= (val,{tst & tasknr = tasknr, hst = hst})

// same, but additionally deleting subtasks

repeatTask_GC :: (Task a) -> Task a | iCreateAndPrint a
repeatTask_GC task = mkTask "repeatTask_GC" repeatTask`
where
	repeatTask` tst=:{tasknr}		
	# (val,tst=:{activated})	= task {tst & tasknr = [-1:tasknr]}					// shift tasknr
	| activated 				= repeatTask` (deleteSubTasks tasknr {tst & tasknr = tasknr}) // loop
	= (val,tst)					

newTask_GC :: !String (Task a) -> (Task a) 	| iData a 
newTask_GC taskname mytask = mkTask taskname (newTask` True mytask)

deleteSubTasks :: ![Int] TSt -> TSt
deleteSubTasks tasknr tst=:{hst} = {tst & hst = deleteIData (subtasksids tasknr) hst}
where
	subtasksids tasknr formid
	# prefix 		= itaskId tasknr ""
	# lprefix 		= size prefix
	# lformid 		= size formid
	= prefix <= formid && lformid > lprefix	

// parallel subtask creation utility

mkParSubTask :: !String !Int (Task a) -> (Task a)  | iCreateAndPrint a		// two shifts are needed
mkParSubTask name i task = mkParSubTask`
where
	mkParSubTask` tst=:{tasknr}
	# (v,tst) = mkTaskNoInc (name <+++ "." <+++ i) mysubtask {tst & tasknr = [i:tasknr],activated = True} // shift task
	= (v,{tst & tasknr = tasknr})
	where
		mysubtask tst=:{tasknr} = task {tst & tasknr = [-1:tasknr], activated = True}	// shift once again!

// assigning tasks to users, each user is identified by a number

(@:) infix 4 :: !(!String,!Int) (Task a)	-> (Task a)			| iCreate a
(@:) (taskname,userId) taska = \tst=:{myId} -> assignTask` myId {tst & myId = userId}
where
	assignTask` myId tst=:{html=ohtml,activated}
	| not activated						= (createDefault,tst)
	# (a,tst=:{html=nhtml,activated})	= taska {tst & html = BT [],myId = userId}		// activate task of indicated user
	| activated 						= (a,{tst & activated = True
												  ,	myId = myId							// work is done						
												  ,	html = ohtml +|+ 					// clear screen
													((userId,taskname) @@: nhtml)})	
	= (a,{tst & myId = myId																// restore user Id
			  , html = 	ohtml +|+ 
						BT [Br, Txt ("Waiting for Task "), yellow taskname, Txt " from ", showUser userId,Br] +|+ 
						((userId,taskname) @@: BT [Txt "Requested by ", showUser myId,Br,Br] +|+ nhtml)})				// combine html code, filter later					

(@::) infix 4 :: !Int (Task a)	-> (Task a)			| iCreate  a
(@::) userId taska = \tst=:{myId} -> assignTask` myId {tst & myId = userId}
where
	assignTask` myId tst=:{html,activated}
	| not activated						= (createDefault,tst)
	# (a,tst=:{html=nhtml,activated})	= taska {tst & html = BT [],myId = userId}		// activate task of indicated user
	| activated 						= (a,{tst & myId = myId							// work is done						
												  ,	html = html})	
	= (a,{tst & myId = myId																// restore user Id
			  , html = 	html +|+  
			  			BT [Br, Txt "Waiting for ", yellow ("Task " <+++ myId), Txt " from ", showUser userId,Br] +|+ 
						((userId,"Task " <+++ myId) @@: 
							BT [Txt "Requested by ", showUser myId,Br,Br] +|+ nhtml)})				// combine html code, filter later					

// sequential tasks

internEditSTask tracename prompt task = \tst -> mkTask tracename (editTask` prompt task) tst

seqTasks :: [(String,Task a)] -> (Task [a])| iCreateAndPrint a
seqTasks options = mkTask "seqTasks" seqTasks`
where
	seqTasks` tst=:{tasknr}
	# (val,tst)	 = doseqTasks options [] {tst & tasknr = [-1:tasknr]}
	= (val,{tst & tasknr = tasknr})

	doseqTasks [] accu tst 		= (reverse accu,{tst & activated = True})
	doseqTasks [(taskname,task):ts] accu tst=:{html} 
	# (a,tst=:{activated=adone,html=ahtml}) 
									= task {tst & activated = True, html = BT []}
	| not adone						= (reverse accu,{tst & html = html +|+ BT [yellow taskname,Br,Br] +|+ ahtml})
	= doseqTasks ts [a:accu] {tst & html = html +|+ ahtml}

// choose one or more tasks out of a collection
buttonTask :: String (Task a) -> (Task a) | iCreateAndPrint a
buttonTask s task = iCTask_button "buttonTask" [(s,task)]

iCTask_button tracename options = mkTask tracename (dochooseTask options)

chooseTask :: [(String,Task a)] -> (Task a) | iCreateAndPrint a
chooseTask options = mkTask "chooseTask" (dochooseTask options)

dochooseTask [] tst				= ireturn_V createDefault tst				
dochooseTask options tst=:{tasknr,html,hst}									// choose one subtask out of the list
# taskId						= itaskId tasknr ("_Or0." <+++ length options)
# buttonId						= itaskId tasknr "_But"
# (chosen,hst)					= mkStoreForm  (Init,cFormId tst.storageInfo taskId -1) id hst
| chosen.value == -1
	# (choice,hst)				= TableFuncBut (Init,cFormId tst.storageInfo buttonId [[(but txt,\_ -> n) \\ txt <- map fst options & n <- [0..]]] <@ Page) hst
	# (chosen,hst)				= mkStoreForm  (Init,cFormId tst.storageInfo taskId -1) choice.value hst
	| chosen.value == -1		= (createDefault,{tst & activated =False,html = html +|+ BT choice.form, hst = hst})
	# chosenTask				= snd (options!!chosen.value)
	# (a,tst=:{activated=adone,html=ahtml,hst}) = chosenTask {tst & tasknr = [-1:tasknr], activated = True, html = BT [], hst = hst}
	= (a,{tst & tasknr = tasknr, activated = adone, html = html +|+ ahtml,hst = hst})
# chosenTask					= snd (options!!chosen.value)
# (a,tst=:{activated=adone,html=ahtml,hst}) = chosenTask {tst & tasknr = [-1:tasknr], activated = True, html = BT [], hst = hst}
= (a,{tst & tasknr = tasknr, activated = adone, html = html +|+ ahtml,hst = hst})

but i = LButton defpixel i

chooseTask_pdm :: [(String,Task a)] -> (Task a) |iCreateAndPrint a
chooseTask_pdm options = mkTask "chooseTask_pdm" (dochooseTask_pdm options)
where
	dochooseTask_pdm [] tst			= (createDefault,{tst& activated = True})	
	dochooseTask_pdm options tst=:{tasknr,html,hst}								// choose one subtask out of the list
	# taskId						= itaskId tasknr ("_Or0." <+++ length options)
	# (choice,hst)					= FuncMenu  (Init,cFormId tst.storageInfo taskId (0,[(txt,id) \\ txt <- map fst options]))	hst
	# (_,tst=:{activated=adone,html=ahtml})	
									= internEditSTask "" "Done" Void {tst & activated = True, html = BT [], hst = hst,tasknr = [-1:tasknr]} 	
	| not adone						= (createDefault,{tst & activated = False, html = html +|+ BT choice.form +|+ ahtml, tasknr = tasknr})
	# chosenIdx						= snd choice.value
	# chosenTask					= snd (options!!chosenIdx)
	# (a,tst=:{activated=bdone,html=bhtml,hst}) 
									= chosenTask {tst & activated = True, html = BT [], tasknr = [0:tasknr]}
	= (a,{tst & activated = adone&&bdone, html = html +|+ bhtml,hst = hst, tasknr = tasknr})
	
mchoiceTasks :: [(String,Task a)] -> (Task [a]) | iCreateAndPrint a
mchoiceTasks options = mkTask "mchoiceTask" (domchoiceTasks options)
where
	domchoiceTasks [] tst			= ([],{tst& activated = True})
	domchoiceTasks options tst=:{tasknr,html,hst}									// choose one subtask out of the list
	# taskId						= itaskId tasknr ("_MLC." <+++ length options)
	# (cboxes,hst)					= ListFuncCheckBox (Init,cFormId tst.storageInfo taskId initCheckboxes) hst
	# optionsform					= cboxes.form <=|> [Txt text \\ (text,_) <- options]
	# (_,tst=:{html=ahtml,activated = adone})
									= (internEditSTask "" "OK" Void <<@ Page)	{tst & activated = True, html = BT [],hst = hst,tasknr = [-1:tasknr]} 
	| not adone						= seqTasks [] {tst & html=html +|+ BT [optionsform] +|+ ahtml,tasknr = [0:tasknr]}
	# mytasks						= [option \\ option <- options & True <- snd cboxes.value]
	# (val,tst)						= seqTasks mytasks {tst & tasknr = [0:tasknr]}
	= (val,{tst & tasknr = tasknr})

	initCheckboxes  = 
		[(CBNotChecked  text,  \ b bs id -> id) \\ (text,_) <- options]

// tasks ending as soon as one of its subtasks completes

orTask :: (Task a,Task a) -> (Task a) | iCreateAndPrint a
orTask (taska,taskb) = mkTask "orTask" (doorTask (taska,taskb))
where
	doorTask (taska,taskb) tst=:{tasknr,html}
	# (a,tst=:{activated=adone,html=ahtml})	= mkParSubTask "orTask" 0 taska {tst & html = BT []}
	# (b,tst=:{activated=bdone,html=bhtml})	= mkParSubTask "orTask" 1 taskb {tst & tasknr = tasknr, html = BT []}
	# (aorb,aorbdone,myhtml)				= if adone (a,adone,ahtml) (if bdone (b,bdone,bhtml) (a,False,ahtml +|+ bhtml))
	= (aorb,{tst & activated = aorbdone, html = html +|+ myhtml})

orTask2 :: (Task a,Task b) -> (Task (EITHER a b)) | iCreateAndPrint a & iCreateAndPrint b
orTask2 (taska,taskb) = mkTask "orTask2" (doorTask (taska,taskb))
where
	doorTask (taska,taskb) tst=:{tasknr,html}
	# (a,tst=:{activated=adone,html=ahtml})	= mkParSubTask "orTask" 0 taska {tst & html = BT []}
	# (b,tst=:{activated=bdone,html=bhtml})	= mkParSubTask "orTask" 1 taskb {tst & tasknr = tasknr, html = BT []}
	# (aorb,aorbdone,myhtml)				= if adone (LEFT a,adone,ahtml) (if bdone (RIGHT b,bdone,bhtml) (LEFT a,False,ahtml +|+ bhtml))
	= (aorb,{tst & activated = aorbdone, html = html +|+ myhtml})

checkAnyTasks traceid taskoptions (ctasknr,skipnr) (bool,which) tst=:{tasknr}
| ctasknr == length taskoptions	= (bool,which,tst)
| ctasknr == skipnr				= checkAnyTasks traceid taskoptions (inc ctasknr,skipnr) (bool,which) tst
# task							= taskoptions!!ctasknr
# (a,tst=:{activated = adone})	= mkParSubTask traceid ctasknr task {tst & tasknr = tasknr, activated = True}
= checkAnyTasks traceid taskoptions (inc ctasknr,skipnr) (bool||adone,if adone ctasknr which) {tst & tasknr = tasknr, activated = True}

orTasks :: [(String,Task a)] -> (Task a) | iCreateAndPrint a
orTasks options = mkTask "orTasks" (doorTasks options)
where
	doorTasks [] tst	= ireturn_V createDefault tst
	doorTasks tasks tst=:{tasknr,html,hst,myId}
	# (chosen,buttons,chosenname,hst) 
						= mkTaskButtons "or Tasks:" "or" tasknr tst.storageInfo (map fst options) hst
	# (finished,which,tst=:{html=allhtml})= checkAnyTasks "orTasks" (map snd options) (0,chosen) (False,0) {tst & html = BT [], hst = hst, activated = True}
	# chosenvalue		= if finished which chosen			// it can be the case that someone else has finshed one of the tasks
	# chosenTaskName	= fst (options!!chosenvalue)
	# chosenTask		= snd (options!!chosenvalue)
	# (a,tst=:{activated=adone,html=ahtml})
						= chosenTask {tst & tasknr = [-1,chosenvalue:tasknr], activated = True, html = BT []}
	| not adone			= (a,{tst 	& activated = adone
									, html =	html +|+ 
												BT buttons +-+ 	(BT chosenname +|+ ahtml) +|+ 
												(myId -@: allhtml)
							})
	= (a,{tst & activated = adone, html = html}) 

andTasks :: [(String,Task a)] -> (Task [a]) | iCreateAndPrint a
andTasks options = mkTask "andTasks" (doandTasks options)
where
	doandTasks [] tst	= ireturn_V [] tst
	doandTasks options tst=:{tasknr,html,myId}
	# (alist,tst=:{activated=finished,html=allhtml})		
						= checkAllTasks "andTasks" options 0 True [] {tst & html = BT [], activated = True}
	| finished			= (map snd alist,{tst & html = html}) 
	# tst=:{hst}		= tst
	# (chosen,buttons,chosenname,hst) 
						= mkTaskButtons "and Tasks:" "and" tasknr tst.storageInfo (map fst options) hst
	# chosenTask		= snd (options!!chosen)
	# chosenTaskName	= fst (options!!chosen)
	# (a,{activated=adone,html=ahtml,hst=hst}) 
						= mkParSubTask "andTasks" chosen chosenTask {tst & tasknr = tasknr, activated = True, html = BT [], hst = hst}
	| not adone			= ([a],{tst & 	hst = hst
									,	activated = False
									, 	html = 	html +|+ 
												BT buttons +-+ 	(BT chosenname +|+ ahtml) +|+ 
												(myId -@: allhtml) 
							})
	# (alist,{activated=finished,html=allhtml,hst = hst})		
						= checkAllTasks "PTasks" options 0 True [] {tst & html = BT [],hst =hst}
	| finished			= (map snd alist,{tst & hst = hst, activated = finished, html = html})
	= (map snd alist,{tst 	& hst = hst
							, activated = finished
							, html = 	html +|+ 
										BT buttons +-+ 	(BT chosenname +|+ ahtml) +|+ 
										(myId -@: allhtml)
						})


andTasks_mstone :: [(String,Task a)] -> (Task [(String,a)]) | iCreateAndPrint a
andTasks_mstone options = mkTask "andTasks_mstone" (PMilestoneTasks` options)
where
	PMilestoneTasks` [] tst	= ireturn_V [] tst
	PMilestoneTasks` options tst=:{tasknr,html,myId}
	# (alist,tst=:{activated=finished,html=allhtml})		
						= checkAllTasks "andTasks" options 0 True [] {tst & html = BT [], activated = True}
	| finished			= (alist,{tst & html = html}) 
	# tst=:{hst}		= tst
	# (chosen,buttons,chosenname,hst) 
						= mkTaskButtons "and Tasks:" "and" tasknr tst.storageInfo (map fst options) hst
	# chosenTask		= snd (options!!chosen)
	# chosenTaskName	= fst (options!!chosen)
	# (a,{activated=adone,html=ahtml,hst=hst}) 
						= mkParSubTask "andTasks" chosen chosenTask {tst & tasknr = tasknr, activated = True, html = BT [], hst = hst}
	# (milestoneReached,_,{hst})	
						= checkAnyTasks "andTasks_mstone" (map snd options) (0,-1) (False,-1) {tst & html = BT [], hst = hst}
	| not adone			= (alist,{tst & hst = hst
									,	activated = adone || milestoneReached
									, 	html = 	html +|+ 
												BT buttons +-+ 	(BT chosenname +|+ ahtml) +|+ 
												(myId -@: allhtml) 
							})
	# (alist,{activated=finished,html=allhtml,hst = hst})		
						= checkAllTasks "PTasks" options 0 True [] {tst & html = BT [],hst =hst}
	| finished			= (alist,{tst & hst = hst, activated = finished, html = html })
	= (alist,{tst 	& hst = hst
							, activated = finished || milestoneReached
							, html = 	html +|+ 
										BT buttons +-+ 	(BT chosenname +|+ ahtml) +|+ 
										(myId -@: allhtml)
						})

// skip should be added for task displayed by user....
checkAllTasks traceid options ctasknr bool alist tst=:{tasknr}
| ctasknr == length options		= (reverse alist,{tst & activated = bool})
# (taskname,task)				= options!!ctasknr
# (a,tst=:{activated = adone})	= mkParSubTask traceid ctasknr task {tst & tasknr = tasknr, activated = True}
= checkAllTasks traceid options (inc ctasknr) (bool&&adone) [(taskname,a):alist] {tst & tasknr = tasknr, activated = True}

// Parallel tasks ending if all complete

andTask :: (Task a,Task b) -> (Task (a,b)) | iCreateAndPrint a & iCreateAndPrint b
andTask (taska,taskb) = mkTask "andTask" (doandTask (taska,taskb))
where
	doandTask (taska,taskb) tst=:{tasknr,html}
	# (a,tst=:{activated=adone,html=ahtml})	= mkParSubTask "andTask" 0 taska {tst & html = BT []}
	# (b,tst=:{activated=bdone,html=bhtml})	= mkParSubTask "andTask" 1 taskb {tst & tasknr = tasknr, html = BT []}
	= ((a,b),{tst & activated = adone&&bdone, html = html +|+ ahtml +|+ bhtml})

andTasks_mu :: String [(Int,Task a)] -> (Task [a]) | iData a
andTasks_mu taskid tasks = newTask "andTasks_mu" (domu_andTasks tasks)
where
	domu_andTasks list tst	= andTasks [(taskid <+++ " " <+++ i, i @:: task) \\ (i,task) <- list] tst

// very experimental higher order lazy task stuf

sharedTask :: (Task Bool) (Task a) -> (Task (Bool,TClosure a)) | iCreateAndPrint a
sharedTask stoptask task =  mkTask "sharedTask" stop`
where
	stop` tst=:{tasknr,html}
	# stopTaskId = [-1,0:tasknr]
	# stopBtnId  = [-1,1:tasknr]
	# (val,tst=:{activated = jobdone,html = jobhtml}) 			= task     {tst & html = BT [], tasknr = stopTaskId}
	# (stopped,tst=:{activated = jobstopped,html = stophtml})	= stoptask {tst & activated = True, html = BT [], tasknr = stopBtnId}
	| jobdone	= return_V (False,TClosure (return_V val)) {tst & html = html +|+ jobhtml, activated = True}
	| stopped	= return_V (True,TClosure (\tst -> task {tst & tasknr = stopTaskId})) {tst & html = html, activated = True}
	= return_V (False,TClosure (return_V val)) {tst & html = html +|+ jobhtml +|+ stophtml}

// time and date related tasks

waitForTimeTask:: HtmlTime	-> (Task HtmlTime)
waitForTimeTask time = mkTask "waitForTimeTask" waitForTimeTask`
where
	waitForTimeTask` tst=:{tasknr,hst}
	# taskId				= itaskId tasknr "_Time_"
	# (stime,hst) 			= mkStoreForm (Init,cFormId tst.storageInfo taskId time) id hst  			// remember time
	# ((currtime,_),hst)	= getTimeAndDate hst
	| currtime < stime.value= (stime.value,{tst & activated = False,hst = hst})
	= (currtime - stime.value,{tst & hst = hst})

waitForTimerTask:: HtmlTime	-> (Task HtmlTime)
waitForTimerTask time  = waitForTimerTask`
where
	waitForTimerTask` tst=:{hst}
	# ((ctime,_),hst)	= getTimeAndDate hst
	= waitForTimeTask (ctime + time) {tst & hst = hst}

waitForDateTask:: HtmlDate	-> (Task HtmlDate)
waitForDateTask date = mkTask "waitForDateTask" waitForDateTask`
where
	waitForDateTask` tst=:{tasknr,hst}
	# taskId				= itaskId tasknr "_Date_"
	# (taskdone,hst) 		= mkStoreForm (Init,cFormId tst.storageInfo taskId (False,date)) id hst  			// remember date
	# ((_,currdate),hst) 	= getTimeAndDate hst
	| currdate < date		= (date,{tst & activated = False, hst = hst})
	= (date,{tst & hst = hst})

// functions on TSt

taskId :: TSt -> (Int,TSt)
taskId tst=:{myId} = (myId,tst)

userId :: TSt -> (Int,TSt)
userId tst=:{userId} = (userId,tst)

addHtml :: [BodyTag] TSt -> TSt
addHtml bodytag  tst=:{activated, html}  
| not activated = tst						// not active, return default value
= {tst & html = html +|+ BT bodytag}		// active, so perform task or get its result

// lifters to iTask state
(*>>) infix 4 :: (TSt -> (a,TSt)) (a -> Task b) -> (Task b)
(*>>) ftst b = doit
where
	doit tst
	# (a,tst) = ftst tst
	= b a tst

(@>>) infix 4 :: (TSt -> TSt) (Task a) -> Task a
(@>>) ftst b = doit
where
	doit tst
	# tst = ftst tst
	= b tst

appIData :: (IDataFun a) -> (Task a) | iData a 
appIData idatafun = \tst -> mkTask "appIData" (appIData` idatafun) tst
where
	appIData` idata tst=:{tasknr,html,hst}
	# (idata,hst) 										= idatafun hst
	# (_,{tasknr,activated,html=ahtml,hst}) 			= internEditSTask "appIDataDone" "Done" Void {tst & activated = True, html = BT [],hst = hst}	
	= (idata.value,{tst & tasknr = tasknr,activated = activated, html = html +|+ 
															(if activated (BT idata.form) (BT idata.form +|+ ahtml)), hst = hst})

appHSt :: (HSt -> (a,HSt)) -> (Task a) | iData a
appHSt fun = mkTask "appHSt" doit
where
	doit tst=:{activated,html,tasknr,hst,storageInfo}
	# taskId			= itaskId tasknr "appHst"
	# (store,hst) 		= mkStoreForm (Init,cFormId storageInfo taskId (False,createDefault)) id hst  			
	# (done,value)		= store.value
	| done 				= (value,{tst & hst = hst})	// if task has completed, don't do it again
	# (value,hst)		= fun hst
	# (store,hst) 		= mkStoreForm (Init,cFormId storageInfo taskId (False,createDefault)) (\_ -> (True,value)) hst 	// remember task status for next time
	# (done,value)		= store.value
	= (value,{tst & activated = done, hst = hst})													// task is now completed, handle as previously
	
Once :: (Task a) -> (Task a) | iData a
Once fun = mkTask "Once" doit
where
	doit tst=:{activated,html,tasknr,hst,storageInfo}
	# taskId			= itaskId tasknr "_Once_"
	# (store,hst) 		= mkStoreForm (Init,cFormId storageInfo taskId (False,createDefault)) id hst  			
	# (done,value)		= store.value
	| done 				= (value,{tst & hst = hst})	// if task has completed, don't do it again
	# (value,tst=:{hst})= fun {tst & hst = hst}
	# (store,hst) 		= mkStoreForm (Init,cFormId storageInfo taskId (False,createDefault)) (\_ -> (True,value)) hst 	// remember task status for next time
	# (done,value)		= store.value
	= (value,{tst & activated = done, hst = hst})													// task is now completed, handle as previously

// Notice that when combining tasks the context restrictions on certain types will get stronger
// It can vary from : no restriction on a -> iTrace a -> iData a
// In most cases the user can simply ask Clean to derive the corresponding generic functions
// For the type Task this will not work since it is a higher order type
// Therefore when yielding a task as result of a task,
// the type Task need to be wrapped into TClosure for which the generic functions are defined below
// Tested for iTrace, will not work for iData

gPrint{|TClosure|} gpa a ps = ps <<- "Task Closure"

gUpd{|TClosure|} gc (UpdSearch _ 0)	  	 c		= (UpdDone, c)								
gUpd{|TClosure|} gc (UpdSearch val cnt)  c		= (UpdSearch val (cnt - 2),c)						
gUpd{|TClosure|} gc (UpdCreate l)        _		
# (mode,default)	= gc (UpdCreate l) undef
= (UpdCreate l, TClosure (\tst -> (default,tst)))			
gUpd{|TClosure|} gc mode                 b		= (mode, b)										



// *** utility section ***

// editors

cFormId  {tasklife,taskstorage,taskmode} s d = {sFormId  s d & lifespan = tasklife, storage = taskstorage, mode = taskmode}
cdFormId {tasklife,taskstorage,taskmode} s d = {sdFormId s d & lifespan = tasklife, storage = taskstorage, mode = taskmode}

// simple html code generation utilities

showUser nr
= yellow ("User " <+++ nr)

yellow message
= Font [Fnt_Color (`Colorname Yellow)] [B [] message]

silver message
= Font [Fnt_Color (`Colorname Silver)] [B [] message]

red message
= Font [Fnt_Color (`Colorname Red)] [B [] message]

// task number generation

showTaskNr [] 		= ""
showTaskNr [i] 		= toString i
showTaskNr [i:is] 	= showTaskNr is <+++ "." <+++ toString i 

itaskId :: ![Int] String -> String
itaskId nr postfix = "iTask_" <+++ (showTaskNr nr) <+++ postfix

InsertTrace :: !Bool ![Int] !Int String !String ![Trace] -> [Trace]
InsertTrace finished idx who taskname val trace = InsertTrace` ridx who val trace
where
	InsertTrace` :: ![Int] !Int !String ![Trace] -> [Trace]
	InsertTrace` [i] 	who str traces
	| i < 0					= abort ("negative task numbers:" <+++ showTaskNr idx <+++ "," <+++ who <+++ "," <+++ taskname)
	# (Trace _ itraces)		= select i traces
	= updateAt` i (Trace (Just (finished,(who,show,taskname,str))) itraces)  traces
	InsertTrace` [i:is] who str traces
	| i < 0					= abort ("negative task numbers:" <+++ showTaskNr idx <+++ "," <+++ who <+++ "," <+++ taskname)
	# (Trace ni itraces)	= select i traces
	# nistraces				= InsertTrace` is who str itraces
	= updateAt` i (Trace ni nistraces) traces

	select :: !Int ![Trace] -> Trace
	select i list
	| i < length list = list!!i 
	=  Trace Nothing []

	show 	= idx //showTaskNr idx
	ridx	= reverse idx

	updateAt`:: !Int !Trace ![Trace] -> [Trace]
	updateAt` n x list
	| n < 0		= abort "negative numbers not allowed"
	= updateAt` n x list
	where
		updateAt`:: !Int !Trace ![Trace] -> [Trace]
		updateAt` 0 x []		= [x]
		updateAt` 0 x [y:ys]	= [x:ys]
		updateAt` n x []		= [Trace Nothing []	: updateAt` (n-1) x []]
		updateAt` n x [y:ys]	= [y      			: updateAt` (n-1) x ys]

printTrace2 Nothing 	= EmptyBody
printTrace2 (Just a)  	= STable emptyBackground (print False a)
where
	print _ []		= []
	print b trace	= [pr b x ++ [STable emptyBackground (print (isDone x||b) xs)]\\ (Trace x xs) <- trace] 

	pr _ Nothing 			= []
	pr dprev (Just (dtask,(w,i,tn,s)))	
	| dprev && (not dtask)	= pr False Nothing	// subtask not important anymore (assume no milestone tasks)
	| not dtask				= showTask cellattr1b White Navy Maroon Silver (w,i,tn,s)
	= showTask cellattr1a White Yellow Red White (w,i,tn,s)
	
	showTask2 attr1 c1 c2 c3 c4 (w,i,tn,s)
	= [Table doneBackground 	[ Tr [] [Td attr1 [font c1 (toString (last (reverse i)))],	Td cellattr2 [font c2 tn]]
								, Tr [] [Td attr1 [font c3 (toString w)], 					Td cellattr2 [font c4 s]]
								]
	  ,Br]

	showTask att c1 c2 c3 c4 (w,i,tn,s)
	= [STable doneBackground 	
		[ [font c1 (toString w),font c2 ("T" <+++ showTaskNr i)]
		, [EmptyBody, font c3 tn]
		, [EmptyBody, font c4 s]
		]
		]
	isDone Nothing = False
	isDone (Just (b,(w,i,tn,s))) = b


	doneBackground = 	[ Tbl_CellPadding (Pixels 1), Tbl_CellSpacing (Pixels 0), cellwidth
						, Tbl_Rules Rul_None, Tbl_Frame Frm_Border 
						]
	doneBackground2 = 	[ Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0), cellwidth
						]
	emptyBackground = 	[Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)]
	cellattr1a		=	[Td_Bgcolor (`Colorname Green),  Td_Width (Pixels 10), Td_VAlign Alo_Absmiddle]
	cellattr1b		=	[Td_Bgcolor (`Colorname Silver), Td_Width (Pixels 10), Td_VAlign Alo_Absmiddle]
	cellattr2		=	[Td_VAlign Alo_Top]
	cellwidth		= 	Tbl_Width (Pixels 130)

	font color message
	= Font [Fnt_Color (`Colorname color), Fnt_Size -1] [B [] message]
	
