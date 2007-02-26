module sum

import StdEnv, StdHtml

// choose one of the following variants

//Start world = doHtmlServer (singleUserTask sequence) world
//Start world = doHtmlServer (singleUserTask sequence3) world
//Start world = doHtmlServer (multiUserTask 3 [setTaskAttribute Persistent] sequenceMU) world
Start world = doHtmlServer sequenceIData2 world

derive gForm []
derive gUpd []

sequence4 :: Task Int
sequence4
= 							STask "OK" 0
				=>> \n ->	PTasks [(toString i,STask "OK" 0) \\ i <- [0..n]]
				=>> \v -> 	returnTask (sum v)



// single user, give first value, then give second, then show sum
// monadic style

sequence :: Task Int
sequence
= 				STask "Set" 0 
	=>> \v1 -> 	STask "Set" 0
	=>> \v2 ->	[Txt "+",Hr []] 
				!>>	returnTask (v1 + v2)
// multi user variant, monadic atyle

sequenceMU :: Task Int
sequenceMU 
= 				(1,"number") @: STask "Set" 0
	=>> \v1 -> 	(2,"number") @: STask "Set" 0 
	=>> \v2 ->	[Txt "+",Hr []] 
				!>> returnTask (v1 + v2) 

// single user, normal Clean style 

sequence2 :: TSt -> (Int,TSt)
sequence2 tst
# (v1,tst) 	= STask "Set" 0 tst
# (v2,tst) 	= STask "Set" 0 tst
# tst		= returnF [Txt "+",Hr []] tst
= returnTask (v1 + v2) tst

sequence3 :: (Task Int)
sequence3 = task 
where
	task tst
	# (v1,tst) 	= STask "Set" createDefault tst
	# (v2,tst) 	= STask "Set" createDefault tst
	# tst		= returnF [Txt "+",Hr []] tst
	= returnTask (v1 + v2) tst

// multi user variant, normal Clean style

sequence2MU :: TSt -> (Int,TSt)
sequence2MU tst
# (v1,tst) 	= ((1,"number") @: STask "Set" 0) tst
# (v2,tst) 	= ((2,"number") @: STask "Set" 0) tst
# tst		= returnF [Txt "+",Hr []] tst
= returnTask (v1 + v2) tst

// iData variant to show what iTasks do for you

sequenceIData hst
# (done1,idata1,hst) = myEdit "v1" 0 hst
# (done2,idata2,hst) = myEdit "v2" 0 hst
=	mkHtml "Solution using iData without iTasks"
	[ 			BodyTag idata1.form
	, if done1 (BodyTag idata2.form) 					  EmptyBody
	, if done2 (BodyTag [Txt "+",Hr [],toHtml (idata1.value + idata2.value)]) EmptyBody
	]  hst
where
	myEdit :: String a HSt -> (Bool,Form a,HSt) | iData a
	myEdit name val hst
	# (idata,hst)	= mkEditForm (Init, nFormId name (HideMode False,val) <@ Submit) hst
	# nval			= snd idata.value
	# done			= idata.changed || fst idata.value == HideMode True
	| done
		# (idata,hst) = mkEditForm (Set,  nFormId name (HideMode done,nval) <@ Display) hst	
		= (True,{idata & value = nval},hst)	
	= (False,{idata & value = nval},hst)	


sequenceIData2 hst
# (done1,val1,form1,hst) = myEditor "v1" 0 hst
# (done2,val2,form2,hst) = myEditor "v2" 0 hst
=	mkHtml "Solution using iData without iTasks"
	[ 			BodyTag form1
	, if done1 (BodyTag form2) 					  EmptyBody
	, if done2 (BodyTag [Txt "+",Hr [],toHtml (val1 + val2)]) EmptyBody
	]  hst

myEditor :: String a *HSt -> (Bool,a,[BodyTag],*HSt) | iData a
myEditor id val hst 
# editId		= id +++ "_Editor"
# buttonId		= id +++ "_Button"
# storeId		= id +++ "_Store"
#(button,hst) 	= simpleButton buttonId "OK" (\_  -> True) hst
#(done,hst)		= mkStoreForm (Init,nFormId storeId False) button.value hst
| done.value	
	# (idata,hst)	= mkEditForm (Init,nFormId  editId val <@ Display) hst
	= (True, idata.value, idata.form ++ [Br], hst)
| otherwise	
	# (idata,hst)	= mkEditForm (Init,nFormId  editId val) hst
	= (False, idata.value, idata.form ++ button.form, hst)
	