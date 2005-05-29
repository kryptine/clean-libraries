implementation module htmlHandler

import StdEnv, ArgEnv, StdMaybe
import htmlDataDef, htmlTrivial
import StdGeneric
import htmlEncodeDecode, htmlStylelib
import GenParse, GenPrint

derive gPrint (,), (,,), (,,,), UpdValue
derive gParse (,), (,,), (,,,), UpdValue
derive gHpr   (,), (,,), (,,,)
derive gUpd		   (,,), (,,,)
 
:: *HSt 		= 	{ cntr 		:: InputId		// counts position in expression
					, states 	:: *FormStates  // all form states are collected here ... 	
					, world		:: *World		// to enable all other kinds of I/O
					}	

:: InputId	 	:== Int						// unique id for every constructor and basic value appearing in the state

:: FormUpdate	:== (InputId,UpdValue)		// info obtained when form is updated

:: UpdValue 	= UpdI Int					// new integer value
				| UpdR Real					// new real value
				| UpdB Bool					// new boolean value
				| UpdC String				// choose indicated constructor 
				| UpdS String				// new piece of text

derive bimap Form, []

toHtml :: a -> BodyTag | gForm {|*|} a
toHtml a 
# (na,_) = gForm{|*|} {id = "__toHtml", livetime = Page, mode = Display} a  {cntr = 0, states = emptyFormStates, world = undef}
= BodyTag na.body

toBody :: (Form a) -> BodyTag
toBody form = BodyTag form.body

setCntr :: InputId *HSt -> *HSt
setCntr i hst = {hst & cntr = i}

ifEdit :: Mode a a -> a
ifEdit Edit 	then else = then
ifEdit Display  then else = else 


// top level function given to end user
// it collects all the html forms to display, adds clean styles and hidden forms, ands prints the html code to stdout

doHtml :: (*HSt -> (Html,!*HSt)) *World -> *World
doHtml pagehandler world 
# (Html (Head headattr headtags) (Body attr bodytags),{states,world}) = pagehandler {cntr = 0, states = initFormStates, world = world}
# (allformbodies,world) = convStates states world
= print_to_stdout (Html (Head headattr [extra_style:headtags]) (Body (extra_body_attr ++ attr) [allformbodies:bodytags])) world
where
	extra_body_attr = [Batt_background "back35.jpg",`Batt_Std [CleanStyle]]
	extra_style = Hd_Style [] CleanStyles	

// swiss army nife editor that makes coffee too ...

mkViewForm :: !FormId d !(HBimap d v) !*HSt -> (Form d,!*HSt) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, TC v
mkViewForm formid initdata bm=:{toForm, updForm, fromForm, resetForm}  {states,world} 
# (isupdated,view,states,world) = findFormInfo formid states world // determine current value in the state store
= calcnextView isupdated view states world
where
	calcnextView isupdated view states world
	# view 		= toForm   initdata  view			// map value to view domain, given previous view value
	# view		= updForm  isupdated view			// apply update function telling user if an update has taken place
	# newval	= fromForm isupdated view			// convert back to data domain	 
	# view		= case resetForm of					// optionally reset the view herafter for next time
						Nothing 	-> view		 
						Just reset 	-> reset view
	# (viewform,{states,world})						// make a form for it
					= gForm{|*|} formid view {cntr = 0,states = states, world = world}
	| viewform.changed && not isupdated 			// only true when a user defined specialisation is updated, recalculate the form
		= calcnextView True (Just viewform.value) states world

	# (states,world) = replaceState formid (viewform.value) states world	// store new value into the store of states

	= (	{changed	= isupdated
		, value		= newval
		, body		= viewform.body
		},{cntr = 0, states = states, world = world})

	findFormInfo :: FormId *FormStates *World -> (Bool,Maybe a,*FormStates,*World) | gUpd{|*|} a & gParse{|*|} a & TC a
	findFormInfo formid formStates world
		= case (decodeInput1 formid formStates world) of

			// an update for this form is detected

			(Just (pos,updval), (True,Just currentState,formStates,world)) 	//state as received from browser 
					-> (True, Just (snd (gUpd{|*|} (UpdSearch updval pos) currentState)),formStates,world)
			(Just (pos,updval), (False,Just currentState,formStates,world)) 	// state has been updated already
					-> (True, Just currentState,formStates,world)

			// no update found, determine the current stored state

			(_, (_,Just currentState, formStates,world))	
					-> (False, Just currentState,formStates,world)

			// no update, no state stored, the current value is taken as (new) state

			(_,(_,_,formStates,world))	-> (False, Nothing,formStates,world)	
	where
		decodeInput1 :: FormId *FormStates *World-> (Maybe FormUpdate, (Bool,Maybe a, *FormStates,*World)) | gParse{|*|} a & TC a
		decodeInput1 formid formStates world
		| CheckUpdateId == formid.id	// this state is updated
		= case CheckUpdate of
			(Just (sid,pos,UpdC s), Just "") 						= (Just (pos,UpdC s)  ,findState (nformid sid) formStates world)
			(Just (sid,pos,UpdC s), _) 								= (Just (pos,UpdC s)  ,findState (nformid sid) formStates world)
			else = case CheckUpdate of
					(Just (sid,pos,UpdI i), Just ni) 				= (Just (pos,UpdI ni) ,findState (nformid sid) formStates world) 
					(Just (sid,pos,UpdI i), _) 						= (Just (pos,UpdI i)  ,findState (nformid sid) formStates world) 
					else = case CheckUpdate of
							(Just (sid,pos,UpdR r), Just nr) 		= (Just (pos,UpdR nr) ,findState (nformid sid) formStates world) 
							(Just (sid,pos,UpdR r), _) 				= (Just (pos,UpdR r) ,findState (nformid sid) formStates world) 
							else = case CheckUpdate of
									(Just (sid,pos,UpdB b), Just nb) 		= (Just (pos,UpdB nb) ,findState (nformid sid) formStates world) 
									(Just (sid,pos,UpdB b), _) 				= (Just (pos,UpdB b) ,findState (nformid sid) formStates world) 
									else = case CheckUpdate of
										(Just (sid,pos,UpdS s),	Just ns)	= (Just (pos,UpdS ns) ,findState (nformid sid) formStates world) 
										(Just (sid,pos,UpdS s),	_)			= (Just (pos,UpdS AnyInput)  ,findState (nformid sid) formStates world) 
										(upd,new) 							= (Nothing, findState formid formStates world)
		| otherwise = (Nothing, findState formid formStates world)

		nformid sid = {formid & id = sid}

// specialize has to be used if a programmer want to specialize gForm
// it remembers the current value of the index in the expression and creates an editor to show this value
// the value might have been changed with this editor, so the value returned might differ form the value you started with !

specialize :: (FormId a *HSt -> (Form a,*HSt)) FormId a *HSt -> (Form a,*HSt) | gUpd {|*|} a
specialize editor formid v hst=:{cntr = inidx,states = formStates,world}
# nextidx = incrIndex inidx v			// this value will be repesented differently, so increment counter 
# (nv,{states,world}) 	= editor nformid v {cntr = 0,states = formStates,world = world}
= (nv,{cntr=nextidx,states = states,world = world})
where
	nformid = {formid & id = formid.id +++ "_" +++ toString inidx}

	incrIndex :: Int v -> Int | gUpd {|*|} v
	incrIndex i v
	# (UpdSearch _ cnt,v) = gUpd {|*|} (UpdSearch (UpdI 0) -1) v
	= i + (-1 - cnt)

// gForm: automatic derives an Html Form for any Clean type

generic gForm a :: !FormId a !*HSt -> *(Form a, !*HSt)	

gForm{|Int|} formid i hst 	
# (body,hst) = mkInput defsize formid (IV i) (UpdI i) hst
= ({changed=False, value=i, body=[body]},hst)

gForm{|Real|} formid r hst 	
# (body,hst) = mkInput defsize formid (RV r) (UpdR r) hst
= ({changed=False, value=r, body=[body]},hst)

gForm{|Bool|} formid b hst 	
# (body,hst) = mkInput defsize formid (BV b) (UpdB b) hst
= ({changed=False, value=b, body=[body]},hst)

gForm{|String|} formid s hst 	
# (body,hst) = mkInput defsize formid (SV s) (UpdS s) hst
= ({changed=False, value=s, body=[body]},hst)

mkInput :: !Int !FormId Value UpdValue *HSt -> (BodyTag,*HSt) 
mkInput size formid=:{mode = Edit} val updval hst=:{cntr} 
	= ( Input 	[	Inp_Type Inp_Text
				, 	Inp_Value val
				,	Inp_Name (encodeInfo (formid.id,cntr,updval))
				,	Inp_Size size
				, 	`Inp_Std [EditBoxStyle]
				,	`Inp_Events	[OnChange callClean]
				] ""
		,setCntr (cntr+1) hst)
mkInput size {mode = Display} val _ hst=:{cntr} 
	= ( Input 	[	Inp_Type Inp_Text
				, 	Inp_Value val
				,	Inp_ReadOnly ReadOnly
				, 	`Inp_Std [DisplayBoxStyle]
				,	Inp_Size size
				] ""
		,setCntr (cntr+1) hst)

gForm{|UNIT|}  _ _ hst 
= ({changed=False, value=UNIT, body=[EmptyBody]},hst)

gForm{|PAIR|} gHa gHb formid (PAIR a b) hst 
# (na,hst) = gHa formid a hst
# (nb,hst) = gHb formid b hst
= (	{changed=na.changed || nb.changed
	,value	=PAIR na.value nb.value
	,body	=[STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [na.body,nb.body]]
	},hst)

gForm{|EITHER|} gHa gHb formid (LEFT a) hst 
# (na,hst) = gHa formid a hst
= ({changed=na.changed, value=LEFT na.value, body=na.body},hst)
gForm{|EITHER|} gHa gHb formid (RIGHT b) hst
# (nb,hst) = gHb formid b hst
= ({changed=nb.changed, value=RIGHT nb.value, body=nb.body},hst)
gForm{|OBJECT|} gHo formid (OBJECT o) hst
# (no,hst) = gHo formid o hst
= ({changed=no.changed, value=OBJECT no.value, body=no.body},hst)

gForm{|CONS of t|} gHc formid (CONS c) hst=:{cntr}
| not (isEmpty t.gcd_fields) 		 
# (nc,hst) = gHc formid c (setCntr (cntr+1) hst) // don't display record constructor
= ({changed=nc.changed, value=CONS nc.value, body=nc.body},hst)
| t.gcd_type_def.gtd_num_conses == 1 
# (nc,hst) = gHc formid c (setCntr (cntr+1) hst) // don't display constructors that have no alternative
= ({changed=nc.changed, value=CONS nc.value, body=nc.body},hst)
| t.gcd_name.[(size t.gcd_name) - 1] == '_' // don't display constructor names which end with an underscore
# (nc,hst) = gHc formid c (setCntr (cntr+1) hst) 
= ({changed=nc.changed, value=CONS nc.value, body=nc.body},hst)
# (selector,hst)= mkConsSelector formid t hst
# (nc,hst) = gHc formid c hst
= ({changed=nc.changed
	,value=CONS nc.value
	,body=[STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[selector,BodyTag nc.body]]]
	},hst)
where
	mkConsSelector formid thiscons hst=:{cntr} 
						= (mkConsSel cntr allnames myindex formid, (setCntr (cntr+1) hst))
	where
		myname   = thiscons.gcd_name
		allnames = map (\n -> n.gcd_name) thiscons.gcd_type_def.gtd_conses
		myindex = find myname allnames 0
		where
			find :: String [String] Int -> Int
			find x [y:ys] idx
			| x == y = idx
			| otherwise = find x ys (idx+1)
			find x [] idx = abort ("cannot find index " +++ x )

	mkConsSel:: Int [String] Int FormId -> BodyTag
	mkConsSel cntr list nr formid
		= Select 	[ Sel_Name ("CS")
					: styles
					]
					[Option  
						[Opt_Value (encodeInfo (formid.id,cntr,UpdC elem))
						: if (j == nr) [Opt_Selected Selected:optionstyle] optionstyle 
						]
						elem
						\\ elem <- list & j <- [0..]
					] 
		where
			styles = case formid.mode of
						Edit	-> 	[ `Sel_Std	[Std_Style width, EditBoxStyle]
									, `Sel_Events [OnChange callClean]
									]
						Display ->	[ `Sel_Std	[Std_Style width, DisplayBoxStyle]
									,  Sel_Disabled Disabled
									]
			optionstyle	= case formid.mode of
							Edit 		-> []
							Display 	-> [`Opt_Std [DisplayBoxStyle]]

			width = "width:" +++ (toString defpixel) +++ "px"

gForm{|FIELD of d |} gHx formid (FIELD x) hst 
# (nx,hst) = gHx formid x hst
= ({changed=nx.changed
	,value=FIELD nx.value
	,body=[STable [Tbl_CellPadding (Pixels 1), Tbl_CellSpacing (Pixels 1)] [[fieldname,BodyTag nx.body]]]
	},hst)
where
//	fieldname2 = Txt [`Std_Attr [DisplayBoxStyle]] (prettyfy d.gfd_name +++ ": ")
						
	fieldname =Input 	[	Inp_Type Inp_Text
						, 	Inp_Value (SV (prettyfy d.gfd_name +++ ": "))
						,	Inp_ReadOnly ReadOnly
						, 	`Inp_Std [DisplayBoxStyle]
						,	Inp_Size maxsize
						] ""

	prettyfy name = mkString [toUpper lname : addspace lnames]
	where
		[lname:lnames] = mkList name
		addspace [] = []
		addspace [c:cs]
		| isUpper c	= [' ',toLower c:addspace cs]
		| otherwise = [c:addspace cs]
		
	maxsize = takemax defsize [size (prettyfy gfd_name)  \\ {gfd_name} <- d.gfd_cons.gcd_fields]
	
	takemax i [] = i
	takemax i [j:js] 
	| i > j = takemax i js
	| otherwise = takemax j js

// gUpd calculates a new value given the current value and a change in the value
// if necessary it invents new default value (e.g. when switching from Nil to Cons ...
// and leaves the rest untouched

:: UpdMode	= UpdSearch UpdValue Int		// search for indicated postion and update it
			| UpdCreate [ConsPos]			// create new values if necessary
			| UpdDone						// and just copy the remaining stuf

generic gUpd t :: UpdMode t -> (UpdMode,t)

gUpd{|Int|} (UpdSearch (UpdI ni) 0) 	_ = (UpdDone,ni)					// update integer value
gUpd{|Int|} (UpdSearch val cnt)     	i = (UpdSearch val (dec cnt),i)		// continue search, don't change
gUpd{|Int|} (UpdCreate l)				_ = (UpdCreate l,0)					// create default value
gUpd{|Int|} mode 			  	    	i = (mode,i)						// don't change

gUpd{|Real|} (UpdSearch (UpdR nr) 0) 	_ = (UpdDone,nr)					// update real value
gUpd{|Real|} (UpdSearch val cnt)     	r = (UpdSearch val (dec cnt),r)		// continue search, don't change
gUpd{|Real|} (UpdCreate l)			 	_ = (UpdCreate l,0.0)				// create default value
gUpd{|Real|} mode 			  	     	r = (mode,r)						// don't change

gUpd{|Bool|} (UpdSearch (UpdB nb) 0) 	_ = (UpdDone,nb)					// update boolean value
gUpd{|Bool|} (UpdSearch val cnt)     	b = (UpdSearch val (dec cnt),b)		// continue search, don't change
gUpd{|Bool|} (UpdCreate l)			 	_ = (UpdCreate l,False)				// create default value
gUpd{|Bool|} mode 			  	     	b = (mode,b)						// don't change

gUpd{|String|} (UpdSearch (UpdS ns) 0) 	_ = (UpdDone,ns)					// update string value
gUpd{|String|} (UpdSearch val cnt)     	s = (UpdSearch val (dec cnt),s)		// continue search, don't change
gUpd{|String|} (UpdCreate l)		   	_ = (UpdCreate l,"")				// create default value
gUpd{|String|} mode 			  	 	s = (mode,s)						// don't change


gUpd{|UNIT|} mode _  = (mode,UNIT)

gUpd{|PAIR|} gUpda gUpdb mode=:(UpdCreate l) _		// invent a pair
# (mode,a) = gUpda mode (abort "PAIR a evaluated")
# (mode,b) = gUpdb mode (abort "PAIR b evaluated")
= (mode,PAIR a b)
gUpd{|PAIR|} gUpda gUpdb mode (PAIR a b)			// pass mode to a and b in all other cases
# (mode,a) = gUpda mode a
# (mode,b) = gUpdb mode b
= (mode,PAIR a b)

gUpd{|EITHER|} gUpda gUpdb (UpdCreate [ConsLeft:cl]) _
# (mode,a) = gUpda (UpdCreate cl) (abort "Left a evaluated")
= (mode,LEFT a)
gUpd{|EITHER|} gUpda gUpdb (UpdCreate [ConsRight:cl]) _
# (mode,b) = gUpdb (UpdCreate cl) (abort "Right b evaluated")
= (mode,RIGHT b)
gUpd{|EITHER|} gUpda gUpdb (UpdCreate []) _ 
# (mode,b) = gUpdb (UpdCreate []) (abort "emty either evaluated")
= (mode,RIGHT b)
gUpd{|EITHER|} gUpda gUpdb mode (LEFT a)
# (mode,a) = gUpda mode a
= (mode,LEFT a)
gUpd{|EITHER|} gUpda gUpdb mode (RIGHT b)
# (mode,b) = gUpdb mode b
= (mode,RIGHT b)

gUpd{|OBJECT|} gUpdo (UpdCreate l) _ 		// invent new type ???
# (mode,o) = gUpdo (UpdCreate l) (abort "Object evaluated")
= (mode,OBJECT o)
gUpd{|OBJECT of typedes|} gUpdo (UpdSearch (UpdC cname) 0) (OBJECT o) // constructor changed of this type
# (mode,o) = gUpdo (UpdCreate path) o
= (UpdDone,OBJECT o)
where
	path = getConsPath (hd [cons \\ cons <- typedes.gtd_conses | cons.gcd_name == cname])
gUpd{|OBJECT|} gUpdo (UpdSearch val cnt) (OBJECT o) // search further
# (mode,o) = gUpdo (UpdSearch val (dec cnt)) o
= (mode,OBJECT o)
gUpd{|OBJECT|} gUpdo mode (OBJECT o)		// other cases
# (mode,o) = gUpdo mode o
= (mode,OBJECT o)

gUpd{|CONS|} gUpdo (UpdCreate l) _ 			// invent new constructor ??
# (mode,c) = gUpdo (UpdCreate l) (abort "Cons evaluated")
= (mode,CONS c)
gUpd{|CONS|} gUpdo mode (CONS c) 			// other cases
# (mode,c) = gUpdo mode c
= (mode,CONS c)

gUpd{|FIELD|} gUpdx mode (FIELD x)  // to be done !!!
# (mode,x) = gUpdx mode x
= (mode,FIELD x)

derive gUpd (,)


// Clean types with a special representation ...

// special representations for lay-out

// tuples are placed next to each other, pairs below each other ...

gForm{|(,)|} gHa gHb formid (a,b) hst=:{cntr}
# (na,hst) = gHa formid a (setCntr (cntr+1) hst)   // one more for the now invisable (,) constructor 
# (nb,hst) = gHb formid b hst
= (	{changed= na.changed || nb.changed
	,value	= (na.value,nb.value)
	,body	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[BodyTag na.body, BodyTag nb.body]]]
	},hst)

gForm{|(,,)|} gHa gHb gHc formid (a,b,c) hst=:{cntr}
# (na,hst) = gHa formid a (setCntr (cntr+1) hst)   // one more for the now invisable (,,) constructor 
# (nb,hst) = gHb formid b hst
# (nc,hst) = gHc formid c hst
= (	{changed= na.changed || nb.changed || nc.changed
	,value	= (na.value,nb.value,nc.value)
	,body	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[BodyTag na.body,BodyTag nb.body,BodyTag nc.body]]]
	},hst)

gForm{|(,,,)|} gHa gHb gHc gHd formid (a,b,c,d) hst=:{cntr}
# (na,hst) = gHa formid a (setCntr (cntr+1) hst)   // one more for the now invisable (,,) constructor 
# (nb,hst) = gHb formid b hst
# (nc,hst) = gHc formid c hst
# (nd,hst) = gHd formid d hst
= (	{changed= na.changed || nb.changed || nc.changed || nd.changed
	,value	= (na.value,nb.value,nc.value,nd.value)
	,body	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] 
				[[BodyTag na.body,BodyTag nb.body,BodyTag nc.body, BodyTag nd.body]]]
	},hst)

// <-> works exactly the same as (,) and places its arguments next to each other, for compatibility with GEC's

gForm{|(<->)|} gHa gHb formid (a <-> b) hst=:{cntr}
# (na,hst) = gHa formid a (setCntr (cntr+1) hst)   // one more for the now invisable <-> constructor 
# (nb,hst) = gHb formid b hst
= (	{changed= na.changed || nb.changed 
	,value	= na.value <-> nb.value
	,body	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[BodyTag na.body, BodyTag nb.body]]]
	},hst)
derive gUpd   <->
derive gParse <->
derive gPrint <->

// <|> works exactly the same as PAIR and places its arguments below each other, for compatibility with GEC's

gForm{|(<|>)|} gHa gHb formid (a <|> b) hst=:{cntr} 
# (na,hst) = gHa formid a (setCntr (cntr+1) hst) // one more for the now invisable <|> constructor
# (nb,hst) = gHb formid b hst
= (	{changed= na.changed || nb.changed 
	,value	= na.value <|> nb.value
	,body	= [STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [na.body, nb.body]]
	},hst)
derive gUpd   <|>
derive gParse <|>
derive gPrint <|>

// to switch between modes within a type ...

gForm{|DisplayMode|} gHa formid (HideMode a) hst=:{cntr} 	
# (na,hst) = gHa {formid & mode = Display} a (setCntr (cntr+1) hst)
= (	{changed= na.changed 
	,value	= HideMode na.value
	,body	= [EmptyBody]
	},hst)
gForm{|DisplayMode|} gHa formid (DisplayMode a) hst=:{cntr}  
# (na,hst) = gHa {formid & mode = Display} a (setCntr (cntr+1) hst)
= (	{changed= False
	,value	= DisplayMode na.value
	,body	= na.body
	},hst)
gForm{|DisplayMode|} gHa formid (EditMode a) hst=:{cntr}  
# (na,hst) = gHa {formid & mode = Edit} a (setCntr (cntr+1) hst)
= (	{changed= na.changed
	,value	= EditMode na.value
	,body	= na.body
	},hst)
gForm{|DisplayMode|} gHa formid EmptyMode hst=:{cntr}
= (	{changed= False
	,value	= EmptyMode
	,body	= [EmptyBody]
	},(setCntr (cntr+1) hst))

derive gUpd DisplayMode
derive gParse DisplayMode
derive gPrint DisplayMode

// Buttons to press

gForm{|Button|} formid  v=:(LButton size bname) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
				[ Inp_Type Inp_Button
				, Inp_Value (SV bname)
				, Inp_Name (encodeInfo (formid.id,cntr,UpdS bname))
				, `Inp_Std [Std_Style ("width:" +++ toString size)]
				, `Inp_Events [OnClick callClean]
				]) ""]
	},(setCntr (cntr+1) hst))
gForm{|Button|} formid v=:(PButton (height,width) ref) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
				[ Inp_Type Inp_Image
				, Inp_Value (SV ref)
				, Inp_Src ref
				, Inp_Name (encodeInfo (formid.id,cntr,UpdS ref))
				, `Inp_Std [Std_Style ("width:" +++ toString width +++ " height:" +++ toString height)]
				, `Inp_Events [OnClick callClean]
				]) ""]
	},(setCntr (cntr+1) hst))
gForm{|Button|} formid Pressed hst = gForm {|*|} formid (LButton defpixel "??") hst // end user should reset button

gUpd{|Button|} (UpdSearch (UpdS name) 0) 	_ = (UpdDone,Pressed)					// update integer value
gUpd{|Button|} (UpdSearch val cnt)      	b = (UpdSearch val (cnt - 1),b)			// continue search, don't change
gUpd{|Button|} (UpdCreate l)				_ = (UpdCreate l,(LButton defsize "Press"))					// create default value
gUpd{|Button|} mode 			  	    	b = (mode,b)							// don't change
derive gParse Button
derive gPrint Button

gForm{|CheckBox|} formid v=:(CBChecked name) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
				[ Inp_Type Inp_Checkbox
				, Inp_Value (SV name)
				, Inp_Name (encodeInfo (formid.id,cntr,UpdS name))
				, Inp_Checked Checked
				, `Inp_Events [OnClick callClean]
				]) ""]
	},(setCntr (cntr+1) hst))

gForm{|CheckBox|} formid v=:(CBNotChecked name) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
				[ Inp_Type Inp_Checkbox
				, Inp_Value (SV name)
				, Inp_Name (encodeInfo (formid.id,cntr,UpdS name))
				, `Inp_Events [OnClick callClean]
				]) ""]
	},(setCntr (cntr+1) hst))

derive gUpd CheckBox
derive gParse CheckBox
derive gPrint CheckBox

gForm{|RadioButton|} formid v=:(RBChecked name) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
				[ Inp_Type Inp_Radio
				, Inp_Value (SV name)
				, Inp_Name (encodeInfo (formid.id,cntr,UpdS name))
				, Inp_Checked Checked
				, `Inp_Events [OnClick callClean]
				]) ""]
	},(setCntr (cntr+1) hst))
gForm{|RadioButton|} formid v=:(RBNotChecked name) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Input (ifEdit formid.mode [] [Inp_Disabled Disabled] ++
				[ Inp_Type Inp_Radio
				, Inp_Value (SV name)
				, Inp_Name (encodeInfo (formid.id,cntr,UpdS name))
				, `Inp_Events [OnClick callClean]
				]) ""]
	},(setCntr (cntr+1) hst))

derive gUpd	  RadioButton
derive gParse RadioButton
derive gPrint RadioButton

gForm{|PullDownMenu|} formid v=:(PullDown (size,width) (menuindex,itemlist)) hst=:{cntr} 
= (	{changed= False
	,value	= v
	,body	= [Select 	(ifEdit formid.mode [] [Sel_Disabled Disabled] ++
					[ Sel_Name ("CS")
					, Sel_Size size
					, `Sel_Std [Std_Style ("width:" +++ (toString width) +++ "px")]
					, `Sel_Events [OnChange callClean]
					])
					[ Option  
						[ Opt_Value (encodeInfo (formid.id,cntr,UpdC (itemlist!!j)))
						: if (j == menuindex) [Opt_Selected Selected] [] 
						]
						elem
						\\ elem <- itemlist & j <- [0..]
					 ]] 	
	},(setCntr (cntr+1) hst))

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
derive gParse PullDownMenu
derive gPrint PullDownMenu


:: TextInput	= TI Int Int						// Input box of size Size for Integers
				| TR Int Real						// Input box of size Size for Reals
				| TS Int String						// Input box of size Size for Strings

gForm{|TextInput|} formid (TI size i) hst 	
# (body,{cntr,states,world}) = mkInput size formid (IV i) (UpdI i) hst
= ({changed=False, value=TI size i, body=[body]},{cntr = cntr+2, states = states,world=world})
gForm{|TextInput|} formid (TR size r) hst	
# (body,{cntr,states,world}) = mkInput size formid (RV r) (UpdR r) hst
= ({changed=False, value=TR size r, body=[body]},{cntr = cntr+2, states = states,world=world})
gForm{|TextInput|} formid (TS size s) hst
# (body,{cntr,states,world}) = mkInput size formid (SV s) (UpdS s) hst 
= ({changed=False, value=TS size s, body=[body]},{cntr = cntr+2, states = states,world=world})

gUpd{|TextInput|} (UpdSearch (UpdI ni) 0) 	(TI size i)  = (UpdDone,TI size ni)		// update integer value
gUpd{|TextInput|} (UpdSearch (UpdR nr) 0) 	(TR size r)  = (UpdDone,TR size nr)		// update integer value
gUpd{|TextInput|} (UpdSearch (UpdS ns) 0) 	(TS size s)  = (UpdDone,TS size ns)		// update integer value
gUpd{|TextInput|} (UpdSearch val cnt)     	i = (UpdSearch val (cnt - 3),i)			// continue search, don't change
gUpd{|TextInput|} (UpdCreate l)				_ = (UpdCreate l,TI defsize 0)			// create default value
gUpd{|TextInput|} mode 			  	    	i = (mode,i)							// don't change

derive gParse TextInput
derive gPrint TextInput

instance toBool RadioButton
where	toBool (RBChecked _)= True
		toBool _ 		 = False

instance toBool CheckBox
where	toBool (CBChecked _)= True
		toBool _ 		 = False

instance toBool Button
where	toBool Pressed = True
		toBool _ 		 = False

// Enabling file IO on HSt

instance FileSystem HSt
where
	fopen :: !{#Char} !Int !*HSt -> (!Bool,!*File,!*HSt)
	fopen string int hst=:{world}
		# (bool,file,world) = fopen string int world
		= (bool,file,{hst & world = world})

	fclose :: !*File !*HSt -> (!Bool,!*HSt)
	fclose file hst=:{world}
		# (bool,world) = fclose file world
		= (bool,{hst & world = world})

	stdio :: !*HSt -> (!*File,!*HSt)
	stdio hst=:{world}
		# (file,world) = stdio world
		= (file,{hst & world = world})

	sfopen :: !{#Char} !Int !*HSt -> (!Bool,!File,!*HSt)
	sfopen string int hst=:{world}
		# (bool,file,world) = sfopen string int world
		= (bool,file,{hst & world = world})


