implementation module htmlButtons

import StdEnv, ArgEnv, StdMaybe

import htmlHandler, htmlStylelib, htmlTrivial

derive gUpd  	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, /*Button, */CheckBox, RadioButton /*, PullDownMenu, TextInput */
derive gPrint 	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, Button, CheckBox, RadioButton, PullDownMenu, TextInput
derive gParse 	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, Button, CheckBox, RadioButton, PullDownMenu, TextInput

:: TextInput	= TI Int Int						// Input box of size Size for Integers
				| TR Int Real						// Input box of size Size for Reals
				| TS Int String						// Input box of size Size for Strings


// Types that have an effect on lay-out

// Tuples are placed next to each other, pairs below each other ...

gForm{|(,)|} gHa gHb formid hst
# (na,hst) = gHa (reuseFormId formid a) (incrHSt 1 hst)   // one more for the now invisable (,) constructor 
# (nb,hst) = gHb (reuseFormId formid b) hst
= (	{changed= na.changed || nb.changed
	,value	= (na.value,nb.value)
	,form	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[BodyTag na.form, BodyTag nb.form]]]
	},hst)
where
	(a,b) = formid.ival

gForm{|(,,)|} gHa gHb gHc formid hst
# (na,hst) = gHa (reuseFormId formid a) (incrHSt 1 hst)   // one more for the now invisable (,,) constructor 
# (nb,hst) = gHb (reuseFormId formid b) hst
# (nc,hst) = gHc (reuseFormId formid c) hst
= (	{changed= na.changed || nb.changed || nc.changed
	,value	= (na.value,nb.value,nc.value)
	,form	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[BodyTag na.form,BodyTag nb.form,BodyTag nc.form]]]
	},hst)
where
	(a,b,c) = formid.ival

gForm{|(,,,)|} gHa gHb gHc gHd formid hst
# (na,hst) = gHa (reuseFormId formid a) (incrHSt 1 hst)   // one more for the now invisable (,,) constructor 
# (nb,hst) = gHb (reuseFormId formid b) hst
# (nc,hst) = gHc (reuseFormId formid c) hst
# (nd,hst) = gHd (reuseFormId formid d) hst
= (	{changed= na.changed || nb.changed || nc.changed || nd.changed
	,value	= (na.value,nb.value,nc.value,nd.value)
	,form	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] 
				[[BodyTag na.form,BodyTag nb.form,BodyTag nc.form, BodyTag nd.form]]]
	},hst)
where
	(a,b,c,d) = formid.ival

// <-> works exactly the same as (,) and places its arguments next to each other, for compatibility with GEC's

gForm{|(<->)|} gHa gHb formid hst
# (na,hst) = gHa (reuseFormId formid a) (incrHSt 1 hst)   // one more for the now invisable <-> constructor 
# (nb,hst) = gHb (reuseFormId formid b) hst
= (	{changed= na.changed || nb.changed 
	,value	= na.value <-> nb.value
	,form	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[BodyTag na.form, BodyTag nb.form]]]
	},hst)
where
	(a <-> b) = formid.ival

// <|> works exactly the same as PAIR and places its arguments below each other, for compatibility with GEC's

gForm{|(<|>)|} gHa gHb formid hst 
# (na,hst) = gHa (reuseFormId formid a) (incrHSt 1 hst) // one more for the now invisable <|> constructor
# (nb,hst) = gHb (reuseFormId formid b) hst
= (	{changed= na.changed || nb.changed 
	,value	= na.value <|> nb.value
	,form	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [na.form, nb.form]]
	},hst)
where
	(a <|> b) = formid.ival

// to switch between modes within a type ...

gForm{|DisplayMode|} gHa formid hst 	
= case formid.ival of
	(HideMode a)
	# (na,hst) = gHa {formid & mode = Display, ival = a} (incrHSt 1 hst)
	= (	{changed= na.changed 
		,value	= HideMode na.value
		,form	= [EmptyBody]
		},hst)
	(DisplayMode a)
	# (na,hst) = gHa {formid & mode = Display, ival = a} (incrHSt 1 hst)
	= (	{changed= False
		,value	= DisplayMode na.value
		,form	= na.form
		},hst)
	(EditMode a) 
	# (na,hst) = gHa {formid & mode = Edit, ival = a} (incrHSt 1 hst)
	= (	{changed= na.changed
		,value	= EditMode na.value
		,form	= na.form
		},hst)
	EmptyMode
	= (	{changed= False
		,value	= EmptyMode
		,form	= [EmptyBody]
		},(incrHSt 1 hst))

// Buttons to press

gForm{|Button|} formid hst 
# (cntr,hst) = CntrHSt hst
= case formid.ival of
	v=:(LButton size bname)
	= (	{changed= False
		,value	= v
		,form	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
					[ Inp_Type Inp_Button
					, Inp_Value (SV bname)
					, Inp_Name (encodeTriplet (formid.id,cntr,UpdS bname))
					, `Inp_Std [Std_Style ("width:" +++ toString size)]
					, `Inp_Events [OnClick callClean]
					]) ""]
		},(incrHSt 1 hst))
	v=:(PButton (height,width) ref)
	= (	{changed= False
		,value	= v
		,form	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
					[ Inp_Type Inp_Image
					, Inp_Value (SV ref)
					, Inp_Name (encodeTriplet (formid.id,cntr,UpdS ref))
					, `Inp_Std [Std_Style ("width:" +++ toString width +++ " height:" +++ toString height)]
					, `Inp_Events [OnClick callClean]
					, Inp_Src ref
					]) ""]
		},(incrHSt 1 hst))
	Pressed
	= gForm {|*|} (setFormId formid (LButton defpixel "??")) hst // end user should reset button


gForm{|CheckBox|} formid hst 
# (cntr,hst) = CntrHSt hst
= case formid.ival of
	v=:(CBChecked name) 
	= (	{changed= False
		,value	= v
		,form	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
					[ Inp_Type Inp_Checkbox
					, Inp_Value (SV name)
					, Inp_Name (encodeTriplet (formid.id,cntr,UpdS name))
					, Inp_Checked Checked
					, `Inp_Events [OnClick callClean]
					]) ""]
		},(incrHSt 1 hst))
	v=:(CBNotChecked name)
	= (	{changed= False
		,value	= v
		,form	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
					[ Inp_Type Inp_Checkbox
					, Inp_Value (SV name)
					, Inp_Name (encodeTriplet (formid.id,cntr,UpdS name))
					, `Inp_Events [OnClick callClean]
					]) ""]
		},(incrHSt 1 hst))

gForm{|RadioButton|} formid hst 
# (cntr,hst) = CntrHSt hst
= case formid.ival of
	v=:(RBChecked name)
	= (	{changed= False
		,value	= v
		,form	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
					[ Inp_Type Inp_Radio
					, Inp_Value (SV name)
					, Inp_Name (encodeTriplet (formid.id,cntr,UpdS name))
					, Inp_Checked Checked
					, `Inp_Events [OnClick callClean]
					]) ""]
		},(incrHSt 1 hst))
	v=:(RBNotChecked name)
	= (	{changed= False
		,value	= v
		,form	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
					[ Inp_Type Inp_Radio
					, Inp_Value (SV name)
					, Inp_Name (encodeTriplet (formid.id,cntr,UpdS name))
					, `Inp_Events [OnClick callClean]
					]) ""]
		},(incrHSt 1 hst))

gForm{|PullDownMenu|} formid  hst 
# (cntr,hst) = CntrHSt hst
= case formid.ival of
	v=:(PullDown (size,width) (menuindex,itemlist))
	= (	{changed= False
		,value	= v
		,form	= [Select 	(ifEdit formid.mode [] [Sel_Disabled Disabled] ++
						[ Sel_Name ("CS")
						, Sel_Size size
						, `Sel_Std [Std_Style ("width:" +++ (toString width) +++ "px")]
						, `Sel_Events [OnChange callClean]
						])
						[ Option  
							[ Opt_Value (encodeTriplet (formid.id,cntr,UpdC (itemlist!!j)))
							: if (j == menuindex) [Opt_Selected Selected] [] 
							]
							elem
							\\ elem <- itemlist & j <- [0..]
						 ]] 	
		},(incrHSt 1 hst))

	
gForm{|TextInput|} formid hst 	
# (cntr,hst) = CntrHSt hst
= case formid.ival of
	(TI size i)
	# (body,hst) = mkInput size formid (IV i) (UpdI i) hst
	= ({changed=False, value=TI size i, form=[body]},incrHSt 2 hst)
	(TR size r)
	# (body,hst) = mkInput size formid (RV r) (UpdR r) hst
	= ({changed=False, value=TR size r, form=[body]},incrHSt 2 hst)
	(TS size s)
	# (body,hst) = mkInput size formid (SV s) (UpdS s) hst 
	= ({changed=False, value=TS size s, form=[body]},incrHSt 2 hst)

gForm {|Date|} formid hst 
	= specialize myeditor (Init,formid) hst
where
	myeditor (init,formid) hst = mkBimapEditor (init,formid) bimap hst
	where
		(Date day month year) = formid.ival

		bimap = {map_to = toPullDown, map_from = fromPullDown}
		where
			toPullDown (Date day month year) = (pddays,pdmonths,pdyears)
			where
				pddays 		= PullDown (1,  defpixel/2) (day-1,  [toString i \\ i <- [1..31]])
				pdmonths 	= PullDown (1,  defpixel/2) (month-1,[toString i \\ i <- [1..12]])
				pdyears 	= PullDown (1,2*defpixel/3) (year-1, [toString i \\ i <- [2005..2010]])
		
			fromPullDown (pddays,pdmonths,pdyears) = Date (convert pddays) (convert pdmonths) (convert pdyears)
			where
				convert x	= toInt (toString x)

	mkBimapEditor :: !(InIDataId d) !(Bimap d v) !*HSt -> (Form d,!*HSt) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, TC v
	mkBimapEditor inIDataId {map_to,map_from} hst
	= mkViewForm inIDataId { toForm 	= toViewMap map_to 
							, updForm 	= \_ v -> v
							, fromForm 	= \_ v -> map_from v
							, resetForm = Nothing
							} hst 

// Update that have to be treated special:

gUpd{|PullDownMenu|} (UpdSearch (UpdC cname) 0) (PullDown (size,width) (menuindex,itemlist)) 
			= (UpdDone,PullDown (size,width) (nmenuindex 0 cname itemlist,itemlist))					// update integer value
where
	nmenuindex cnt name [itemname:items] 
	| name == itemname = cnt
	| otherwise		   = nmenuindex (cnt+1) name items
	nmenuindex _ _ [] = -1
gUpd{|PullDownMenu|} (UpdSearch val cnt) v = (UpdSearch val (cnt - 1),v)			// continue search, don't change
gUpd{|PullDownMenu|} (UpdCreate l)		_ = (UpdCreate l,PullDown (1,defpixel) (0,["error"]))					// create default value
gUpd{|PullDownMenu|} mode 			  	v = (mode,v)							// don't change


gUpd{|Button|} (UpdSearch (UpdS name) 0) 	_ = (UpdDone,Pressed)					// update integer value
gUpd{|Button|} (UpdSearch val cnt)      	b = (UpdSearch val (cnt - 1),b)			// continue search, don't change
gUpd{|Button|} (UpdCreate l)				_ = (UpdCreate l,(LButton defsize "Press"))					// create default value
gUpd{|Button|} mode 			  	    	b = (mode,b)							// don't change

gUpd{|TextInput|} (UpdSearch (UpdI ni) 0) 	(TI size i)  = (UpdDone,TI size ni)		// update integer value
gUpd{|TextInput|} (UpdSearch (UpdR nr) 0) 	(TR size r)  = (UpdDone,TR size nr)		// update integer value
gUpd{|TextInput|} (UpdSearch (UpdS ns) 0) 	(TS size s)  = (UpdDone,TS size ns)		// update integer value
gUpd{|TextInput|} (UpdSearch val cnt)     	i = (UpdSearch val (cnt - 3),i)			// continue search, don't change
gUpd{|TextInput|} (UpdCreate l)				_ = (UpdCreate l,TI defsize 0)			// create default value
gUpd{|TextInput|} mode 			  	    	i = (mode,i)							// don't change

// small utility stuf

instance toBool RadioButton
where	toBool (RBChecked _)= True
		toBool _ 		 = False

instance toBool CheckBox
where	toBool (CBChecked _)= True
		toBool _ 		 = False

instance toBool Button
where	toBool Pressed = True
		toBool _ 		 = False

instance toInt PullDownMenu
where
	toInt:: PullDownMenu -> Int
	toInt (PullDown _ (i,_)) = i

instance toString PullDownMenu
where
	toString (PullDown _ (i,s)) = if (i>=0 && i <length s) (s!!i) ""