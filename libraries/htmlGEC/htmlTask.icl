implementation module htmlTask

import StdEnv, StdHtml

derive gForm 	[], Niks
derive gUpd 	[], Niks
derive gParse 	Niks
derive gPrint 	Niks
derive gerda 	Niks

:: *TSt 		:== (([Int],Bool,[BodyTag]),HSt)   	// Task State: task nr, has this task to be done?, html code accumulator

:: Niks 		= Niks								// to make an empty task

startTask :: (Task a) *HSt -> ([BodyTag],HSt) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
startTask taska hst
# (_,((_,_,html),hst)) = taska (newTask,hst) 
= (html,hst)
where
	newTask = ([],True,[])

mkTask :: (*TSt -> *(a,*TSt)) -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
mkTask mytask = \tst -> mkTask` tst
where
	mkTask` tst=:((i,myturn,html),hst)			
	# tst 			= incTask tst				// every task should first increment its tasknumber
	| not myturn	= (createDefault,tst)		// not active, return default value
	= mytask tst

incTask ((i,b,html),hst) = ((incTasknr i,b,html),hst)
where
	incTasknr [] = [0]
	incTasknr [i:is] = [i+1:is]

mkLTaskRTC :: String b (b -> Task a) *TSt -> ((b -> Task a,Task a),*TSt) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
												& gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC b
mkLTaskRTC s initb batask tst = let (a,b,c) = LazyTask` s (incTask tst) in ((a,b),c)
where
	LazyTask` s tst=:((j,myturn,html),hst) = (bossTask, workerTask s,tst)
	where
		workerTask s tst = mkTask (workerTask` s) tst
		where
			workerTask` s tst=:((i,myturn,html),hst) 
			# (boss,hst)	= bossStore id hst		// check input from boss
			# (worker,hst)	= workerStore id hst	// check result from worker
			# bdone			= fst boss.value
			# binput		= snd boss.value
			# wdone			= fst worker.value
			# wresult		= snd worker.value
			| wdone			= (wresult,((i,True,html<|.|>  [Txt ("Lazy task \"" +++ s +++ "\" completed:")]),hst))	
			| bdone
				# (wresult,((_,wdone,whtml),hst)) = batask binput ((j++[0],True,[]),hst)	// apply task to input from boss
				| wdone															// worker task finshed
					# (_,hst)	= workerStore (\_ -> (wdone,wresult)) hst		// store task and status
					= workerTask` s ((i,myturn,html),hst) 				// complete as before
				= (createDefault,((i,False,html <|.|> if wdone [] [Txt ("lazy task \"" +++ s +++ "\" activated:"),Br] <|.|> whtml),hst))
			= (createDefault,((i,False,html<|.|>[Txt ("Waiting for task \"" +++ s +++ "\"..")]),hst))		// no
	
		bossTask b tst = mkTask bossTask` tst
		where
			bossTask` tst=:((i,myturn,html),hst) 
			# (boss,hst)				= bossStore id hst		// check input from boss
			# (worker,hst)				= workerStore id hst	// check result from worker
			# bdone						= fst boss.value
			# binput					= snd boss.value
			# wdone						= fst worker.value
			# wresult					= snd worker.value
			| bdone && wdone			= (wresult,((i,True,html<|.|>  [Txt ("Result of lazy task \"" +++ s +++ "\" :")]),hst))	// finished
			| not bdone
				# (_, hst)		= bossStore (\_ -> (True,b)) hst	// store b information to communicate to worker	
				= (createDefault,((i,False,html<|.|>[Txt ("Waiting for task \"" +++ s +++ "\"..")]),hst))
			= (createDefault,((i,False,html<|.|>[Txt ("Waiting for task \"" +++ s +++ "\"..")]),hst))	
	
		workerStore   fun = mkStoreForm (Init,sFormId ("workerStore" <+++ mkTaskNr j) (False,createDefault)) fun 
		bossStore     fun = mkStoreForm (Init,sFormId ("bossStore"   <+++ mkTaskNr j) (False,initb)) fun 

mkLTask :: String (Task a) *TSt -> ((Task a,Task a),*TSt) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
mkLTask s task tst = let (a,b,c) = LazyTask` s task (incTask tst) in ((a,b),c)
where
	LazyTask` s task tst=:((j,myturn,html),hst) = (bossTask, workerTask s task,tst)
	where
		workerTask s task tst = mkTask (workerTask` s task) tst
		where
			workerTask` s task tst=:((i,myturn,html),hst) 
			# (todo,hst)	= checkBossSignal id hst	// check whether lazy task evaluation has to be done
			| todo.value								// yes	
				# (a,((_,adone,ahtml),hst)) = task ((j++[0],True,[]),hst)			// do task
				# (_,hst) 					= lazyTaskStore (\_ -> (adone,a)) hst	// store task and status
				= (a,((i,myturn,html <|.|> if adone [] [Txt ("lazy task \"" +++ s +++ "\" activated:"),Br] <|.|> ahtml),hst))
			= (createDefault,((i,myturn,html),hst))		// no
	
		bossTask tst = mkTask (bossTask`) tst
		where
			bossTask` tst=:((i,myturn,html),hst) 
			# buttonId		= "getlt" <+++ mkTaskNr i
			# (finbut,hst)  = simpleButton buttonId s (\_ -> True) hst	// button press will trigger related lazy task	
			# (todo,hst)	= checkBossSignal finbut.value hst			// set store True if button pressed
			# (result,hst)	= lazyTaskStore id hst						// inspect status task
			# (done,value)	= result.value
			| not done 		= (createDefault,((i,False,html<|.|>if todo.value [Txt ("Waiting for task \"" +++ s +++ "\"..")] finbut.form),hst))
			= (value,((i,myturn,html <|.|>  [Txt ("Result of lazy task \"" +++ s +++ "\" :")]),hst))	
	
		lazyTaskStore   fun = mkStoreForm (Init,sFormId ("getLT" <+++ mkTaskNr j) (False,createDefault)) fun 
		checkBossSignal fun = mkStoreForm (Init,sFormId ("setLT" <+++ mkTaskNr j) (fun False)) fun 

returnTask :: a -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
returnTask a = \tst -> mkTask (returnTask` a) tst
where
	returnTask` a ((i,myturn,html),hst)
	# editId			= "edit_" <+++ mkTaskNr i
	# (editor,hst) 		= (mkEditForm  (Set,ndFormId editId a) hst)			// yes, read out current value, make editor passive
	= (editor.value,((i,myturn,html <|.|> editor.form),hst))				// return result task

returnVF :: a [BodyTag] -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
returnVF a bodytag =
	\tst=:((i,myturn,html),hst) -> (a,((i,myturn,html <|.|> bodytag),hst))				// return result task

returnV :: a -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
returnV a  = 
	\tst  -> (a,tst)				// return result task

returnF :: [BodyTag] -> TSt -> TSt
returnF bodytag =
	\tst=:((i,myturn,html),hst) -> ((i,myturn,html <|.|> bodytag),hst)				// return result task

STask :: String a -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
STask prompt a = \tst -> mkTask (STask` a) tst
where
	STask` a ((i,myturn,html),hst)
	# taskId			= "Stask_" <+++ mkTaskNr i
	# editId			= "Sedit_" <+++ mkTaskNr i
	# buttonId			= mkTaskNr i
	# (taskdone,hst) 	= mkStoreForm (Init,sFormId taskId False) id hst  			// remember if the task done
	| taskdone.value																// test if task completed
		# (editor,hst) 	= (mkEditForm  (Init,ndFormId editId a) hst)				// yes, read out current value, make editor passive
		= (editor.value,((i,True,html <|.|> editor.form),hst))						// return result task
	# (editor,hst) 		= mkEditForm  (Init,sFormId editId a) hst					// no, read out current value from active editor
	# (finbut,hst)  	= simpleButton buttonId prompt (\_ -> True) hst				// add button for marking task as done
	# (taskdone,hst) 	= mkStoreForm (Init,sFormId taskId False) finbut.value hst 	// remember task status for next time
	| taskdone.value	= STask` a ((i,myturn,html),hst)							// task is now completed, handle as previously
	= (a,((i,taskdone.value,html <|.|> (editor.form ++ finbut.form)),hst))

CTask_pdmenu :: [(String,Task a)] -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
CTask_pdmenu options = \tst -> mkTask (doCTask` options) tst
where
	doCTask` [] tst					= returnV createDefault tst	
	doCTask` options tst=:((i,myturn,html),hst)									// choose one subtask out of the list
	# (choice,hst)					= FuncMenu  (Init,sFormId ("Cpd_task_" <+++ mkTaskNr i) (0,[(txt,id) \\ txt <- map fst options]))	hst
	# (_,((i,adone,ahtml),hst)) 	= STask  "Cpd_Done" Niks ((i ++ [0],True,[]),hst)	
	| not adone						= (createDefault,((i,False,html <|.|> choice.form <|.|> ahtml),hst))
	# chosenIdx						= snd choice.value
	# chosenTask					= snd (options!!chosenIdx)
	# (a,((i,bdone,bhtml),hst)) 	= chosenTask ((i ++ [1],True,[]),hst)
	= (a,((i,adone&&bdone,html <|.|> bhtml),hst))

CTask_button :: [(String,Task a)] -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
CTask_button options = \tst -> mkTask (doCTask` options) tst
where
	doCTask` [] tst					= returnV createDefault tst				
	doCTask` options tst=:((i,myturn,html),hst)									// choose one subtask out of the list
	# (choice,hst)					= TableFuncBut (Init,sFormId ("Cbt_task_" <+++ mkTaskNr i) [[(but txt,\_ -> n) \\ txt <- map fst options & n <- [0..]]]) hst
	# (chosen,hst)					= mkStoreForm  (Init,sFormId ("Cbt_chosen_" <+++ mkTaskNr i) -1) choice.value hst
	| chosen.value == -1			= (createDefault,((i,False,html <|.|> choice.form),hst))
	# chosenTask					= snd (options!!chosen.value)
	# (a,((i,adone,ahtml),hst)) 	= chosenTask ((i ++ [1],True,[]),hst)
	= (a,((i,adone,html <|.|> ahtml),hst))

	but i = LButton defpixel i

MCTask_ckbox :: [(String,Task a)] -> (Task [a]) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
MCTask_ckbox options = \tst -> mkTask (MCTask_ckbox` options) tst
where
	MCTask_ckbox` [] tst			= returnV [] tst	
	MCTask_ckbox` options tst=:((i,myturn,html),hst)									// choose one subtask out of the list
	# (cboxes,hst)					= ListFuncCheckBox (Init,sFormId ("MC_check" <+++ mkTaskNr i) initCheckboxes) hst
	# optionsform					= cboxes.form <=|> [Txt text \\ (text,_) <- options]
	# (_,((i,adone,ahtml),hst)) 	= STask  "OK" Niks ((i,True,[]),hst)	
	| not adone						= (createDefault,((i,False,html <|.|> [optionsform] <|.|> ahtml),hst))
	# mytasks						= [option \\ option <- options & True <- snd cboxes.value]
	= STasks mytasks ((i,True,html),hst)

	initCheckboxes  = 
		[(CBNotChecked  text,  \ b bs id -> id) \\ (text,_) <- options]

STasks :: [(String,Task a)] -> (Task [a])| gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
STasks options = \tst -> mkTask (doSandTasks` options []) tst
where
	doSandTasks` [] accu tst 		= returnV (reverse accu) tst
	doSandTasks` [(txt,task):ts] accu tst=:((i,myturn,html),hst)	 
	# (a,((i,adone,ahtml),hst)) 	= task ((i,True,[]),hst)
	| not adone						= (reverse accu,((i,adone,html <|.|> [Txt ("Task: " +++ txt),Br] <|.|> ahtml),hst))
	= mkTask (doSandTasks` ts [a:accu]) ((i,adone,html <|.|> ahtml),hst)


PTask2 :: (Task a,Task b) -> (Task (a,b)) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a & gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC b
PTask2 (taska,taskb) = \tst -> mkTask (PTask2` (taska,taskb)) tst
where
	PTask2` (taska,taskb) tst=:((i,myturn,html),hst)
	# (a,((_,adone,ahtml),hst)) 	= taska ((i ++ [0],True,[]),hst)	
	# (b,((_,bdone,bhtml),hst)) 	= taskb ((i ++ [1],True,[]),hst)
	= ((a,b),((i,adone&&bdone,html <|.|> ahtml <|.|> bhtml),hst))

PCTask2 :: (Task a,Task a) -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
PCTask2 (taska,taskb) = \tst -> mkTask (PCTask2` (taska,taskb)) tst
where
	PCTask2` (taska,taskb) tst=:((i,myturn,html),hst)
	# (a,((_,adone,ahtml),hst)) 	= taska ((i ++ [0],True,[]),hst)	
	# (b,((_,bdone,bhtml),hst)) 	= taskb ((i ++ [1],True,[]),hst)
	# (aorb,aorbdone,myhtml)		= if adone (a,adone,ahtml) (if bdone (b,bdone,bhtml) (a,False,ahtml <|.|> bhtml))
	= (aorb,((i,aorbdone,html <|.|> myhtml),hst))

PCTasks :: [(String,Task a)] -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
PCTasks options = \tst -> mkTask (PCTasks` options) tst
where
	PCTasks` [] tst 				= returnV createDefault tst
	PCTasks` tasks tst=:((i,myturn,html),hst)
	# (choice,hst)					= TableFuncBut (Init,sFormId ("Cbt_task_" <+++ mkTaskNr i) [[(but txt,\_ -> n)] \\ txt <- map fst options & n <- [0..]]) hst
	# (chosen,hst)					= mkStoreForm  (Init,sFormId ("Cbt_chosen_" <+++ mkTaskNr i) 0) choice.value hst
	# chosenTask					= snd (options!!chosen.value)
	# (a,((i,adone,ahtml),hst)) 	= chosenTask ((i ++ [chosen.value + 1],True,[]),hst)
	| not adone						= (a,((i,adone,html <|.|> [choice.form <=> ahtml]),hst))
	= (a,((i,adone,html <|.|> ahtml),hst))

	but i = LButton defpixel i

PTasks :: [(String,Task a)] -> (Task [a]) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a 
PTasks options = \tst -> mkTask (doPTasks` options) tst
where
	doPTasks` [] tst			= returnV [] tst
	doPTasks` options tst=:((i,myturn,html),hst)
	# (choice,hst)				= TableFuncBut (Init,sFormId ("Cbt_task_" <+++ mkTaskNr i) [[(but txt,\_ -> n)] \\ txt <- map fst options & n <- [0..]]) hst
	# (chosen,hst)				= mkStoreForm  (Init,sFormId ("Cbt_chosen_" <+++ mkTaskNr i) 0) choice.value hst
	# chosenTask				= snd (options!!chosen.value)
	# chosenTaskName				= fst (options!!chosen.value)
	# (a,((_,adone,ahtml),hst)) = chosenTask ((i ++ [chosen.value + 1],True,[]),hst)
	| not adone					= ([a],((i,adone,html <|.|> [choice.form <=> ( [Txt ("Task: " +++ chosenTaskName)] <|.|> ahtml)]),hst))
	# (alist,((_,finished,_),hst))		
								= checkAllTasks 0 [] ((i,myturn,[]),hst)
	| finished					= (alist,((i,finished,html),hst))
	= ([a],((i,finished,html <|.|> [choice.form <=> ([Txt ("Task: " +++ chosenTaskName)] <|.|> ahtml)]),hst))

	but i = LButton defpixel i

	checkAllTasks tasknr alist tst=:((i,myturn,_),hst)
	| tasknr == length options	= (reverse alist,((i,True,[]),hst))	
	# task						= snd (options!!tasknr)
	# (a,((_,adone,html),hst))	= task ((i ++ [tasknr + 1],True,[]),hst)
	| adone						= checkAllTasks (inc tasknr) [a:alist] ((i,myturn,[]),hst)
	= ([],((i,False,[]),hst))

STask_button 		:: String (Task a) 			-> (Task a) 	| gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
STask_button s task = CTask_button [(s,task)]


// utility section

mkTaskNr [] = ""
mkTaskNr [i:is] = toString i <+++ "." <+++ mkTaskNr is


appIData :: (IDataFun a) -> (Task a) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, gerda{|*|}, TC a
appIData idatafun = \tst -> mkTask (appIData` idatafun) tst
where
	appIData` idata tst=:((i,myturn,html),hst)
	# (idata,hst) 				= idatafun hst
	# (_,((i,adone,ahtml),hst)) = STask  "Done" Niks ((i,True,[]),hst)	
	= (idata.value,((i,adone,html <|.|> if adone idata.form (idata.form <|.|> ahtml)),hst))
	
	