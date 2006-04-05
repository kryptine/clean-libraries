implementation module htmlHandler

import StdEnv, ArgEnv, StdMaybe
import htmlDataDef, htmlTrivial
import StdGeneric
import iDataState, htmlStylelib
import GenParse, GenPrint
import httpServer

derive gPrint (,), (,,), (,,,), UpdValue
derive gParse (,), (,,), (,,,), UpdValue
derive gHpr   (,), (,,), (,,,)
derive gUpd		   (,,), (,,,)
derive bimap Form, [], FormId
 
gParse {|(->)|} gArg gRes _ 	= Nothing 
gPrint{|(->)|} gArg gRes  _ _	= abort "functions can only be used with dynamic storage option!\n" 

:: *HSt 		= 	{ cntr 		:: InputId		// counts position in expression
					, states 	:: *FormStates  // all form states are collected here ... 	
					, world		:: *NWorld		// to enable all other kinds of I/O
					}	

:: InputId	 	:== Int						// unique id for every constructor and basic value appearing in the state

:: FormUpdate	:== (InputId,UpdValue)		// info obtained when form is updated

// top level function given to end user
// it collects all the html forms to display, adds clean styles and hidden forms, ands prints the html code to stdout
// assumes that the application is used by a server

doHtml :: .(*HSt -> (Html,!*HSt)) *World -> *World
doHtml userpage world 
# (inout,world) 		= stdio world						// open stdin and stdout channels
# nworld 				= { worldC = world, inout = inout }	
# (initforms,nworld) 	= retrieveFormStates External Nothing nworld
# (Html (Head headattr headtags) (Body attr bodytags),{states,world}) 
						= userpage {cntr = 0, states = initforms, world = nworld}
# (allformbodies,world) = storeFormStates states world
# {worldC}				= print_to_stdout 
								(Html (Head headattr [extra_style:headtags]) 
								(Body (extra_body_attr ++ attr) [debugInput,allformbodies:bodytags]))
								world
= worldC
where
	stuf = "Hello world"

	extra_body_attr = [Batt_background "back35.jpg",`Batt_Std [CleanStyle]]
	extra_style = Hd_Style [] CleanStyles	

	debugInput = if TraceInput (traceHtmlInput External Nothing) EmptyBody

// same as doHtml, but now a Clean Server will be included

//doHtmlServer :: .(*HSt -> (Html,!*HSt)) *World -> *World   // this one is rejected !!
doHtmlServer :: (*HSt -> (Html,!*HSt)) *World -> *World
doHtmlServer userpage world
	= StartServer 80 (map (\(id,_,f) -> (id,f)) pages) world
where
//	pages :: [(String,String, String String Arguments *World -> ([String],String,*World))]
	pages
		=	[("clean", "CleanExample", \_ _ a  -> doHtmlServer2 (conv a) userpage)
			]
	conv args =  foldl (+++) "" (map (\(x,y) -> y) args)

	doHtmlServer2 :: String .(*HSt -> (Html,!*HSt)) *World -> ([String],String,*World)
	doHtmlServer2 args userpage world 
	# (ok,temp,world) 		= fopen "temp" FWriteText world						// open stdin and stdout channels
	# nworld 				= { worldC = world, inout = temp }	
	# (initforms,nworld) 	= retrieveFormStates Internal (Just args) nworld
	# (Html (Head headattr headtags) (Body attr bodytags),{states,world}) 
							= userpage {cntr = 0, states = initforms, world = nworld}
	# (allformbodies,world) = storeFormStates states world
	# {worldC,inout}		= print_to_stdout 
										(Html (Head headattr [extra_style:headtags]) 
										(Body (extra_body_attr ++ attr) [debugInput,allformbodies:bodytags])) 
										world
	# (ok,world)			= fclose inout worldC
	# (allhtmlcode,world)	= readoutcompletefile "temp" world	
	= ([],allhtmlcode,world)
	where
		extra_body_attr = [Batt_background "back35.jpg",`Batt_Std [CleanStyle]]
		extra_style = Hd_Style [] CleanStyles	
	
		readoutcompletefile name env
		# (ok,file,env) = fopen name FReadText env
		# (text,file)	= freads file 1000000
		# (ok,env)		= fclose file env
		= (text,env)
	
		debugInput = if TraceInput (traceHtmlInput Internal (Just args)) EmptyBody

// swiss army nife editor that makes coffee too ...

mkViewForm :: !(InIDataId d) !(HBimap d v) !*HSt -> (Form d,!*HSt) | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, TC v
mkViewForm (init,formid) bm=:{toForm, updForm, fromForm, resetForm}  {states,world} 
# (isupdated,view,states,world) = findFormInfo vformid states world // determine current value in the state store
= calcnextView isupdated view states world
where
	vformid = (reuseFormId formid (toForm init formid.ival Nothing))

	calcnextView isupdated view states world
	# (changedid,states) = getUpdateId states
	# view 		= toForm  init formid.ival view			// map value to view domain, given previous view value
	# view		= updForm  {isChanged = isupdated, changedId = changedid} view			// apply update function telling user if an update has taken place
	# newval	= fromForm {isChanged = isupdated, changedId = changedid} view			// convert back to data domain	 
	# view		= case resetForm of					// optionally reset the view herafter for next time
						Nothing 	-> view		 
						Just reset 	-> reset view
// added

	| formid.mode == NoForm							// NEW : don't make a form at all
		# (states,world) = replaceState vformid view states world	// store new value into the store of states
		= (	{changed	= False
			, value		= newval
			, form		= []
			},{cntr = 0, states = states, world = world})

// end added

	# (viewform,{states,world})						// make a form for it
					= gForm{|*|} (init,reuseFormId formid view) {cntr = 0,states = states, world = world}
	| viewform.changed && not isupdated 			// only true when a user defined specialisation is updated, recalculate the form
		= calcnextView True (Just viewform.value) states world

	# (states,world) = replaceState vformid (viewform.value) states world	// store new value into the store of states

	= (	{changed	= isupdated
		, value		= newval
		, form		= viewform.form
		},{cntr = 0, states = states, world = world})

//	findFormInfo :: FormId *FormStates *NWorld -> (Bool,Maybe a,*FormStates,*NWorld) | gUpd{|*|} a & gParse{|*|} a & TC a
	findFormInfo formid formStates world
		= case (decodeInput1 formid formStates world) of

			// an update for this form is detected

			(Just (pos,updval), (True,Just currentState,formStates,world)) 		//state as received from browser 
					-> (True, Just (snd (gUpd{|*|} (UpdSearch updval pos) currentState)),formStates,world)
			(Just (pos,updval), (False,Just currentState,formStates,world)) 	// state has been updated already
					-> (False, Just currentState,formStates,world)   			// to indicate the update already has taken place, used in arrows

			// no update found, determine the current stored state

			(_, (_,Just currentState, formStates,world))	
					-> (False, Just currentState,formStates,world)

			// no update, no state stored, the current value is taken as (new) state

			(_,(_,_,formStates,world))	-> (False, Nothing,formStates,world)	
	where
//		decodeInput1 :: (FormId b) *FormStates *NWorld-> (Maybe FormUpdate, (Bool,Maybe b, *FormStates,*NWorld)) | gParse{|*|} b & TC b
		decodeInput1 formid fs world
		# (updateid,fs) = getUpdateId fs
		# (anyInput,fs) = getUpdate fs 
		| updateid == formid.id	// this state is updated
		= case getTriplet fs of
			(Just (sid,pos,UpdC s), Just "",fs) 							= (Just (pos,UpdC s)  ,findState (nformid sid) fs world)
			(Just (sid,pos,UpdC s), _,fs) 									= (Just (pos,UpdC s)  ,findState (nformid sid) fs world)
			(_,_,fs)= case getTriplet fs of
					(Just (sid,pos,UpdI i), Just ni,fs) 					= (Just (pos,UpdI ni) ,findState (nformid sid) fs world) 
					(Just (sid,pos,UpdI i), _,fs) 							= (Just (pos,UpdI i)  ,findState (nformid sid) fs world) 
					(_,_,fs) = case getTriplet fs of
							(Just (sid,pos,UpdR r), Just nr,fs) 			= (Just (pos,UpdR nr) ,findState (nformid sid) fs world) 
							(Just (sid,pos,UpdR r), _,fs) 					= (Just (pos,UpdR r) ,findState (nformid sid) fs world) 
							(_,_,fs) = case getTriplet fs of
									(Just (sid,pos,UpdB b), Just nb,fs) 	= (Just (pos,UpdB nb) ,findState (nformid sid) fs world) 
									(Just (sid,pos,UpdB b), _,fs) 			= (Just (pos,UpdB b) ,findState (nformid sid) fs world) 
									(_,_,fs) = case getTriplet fs of
										(Just (sid,pos,UpdS s),	Just ns,fs)	= (Just (pos,UpdS ns) ,findState (nformid sid) fs world) 
										(Just (sid,pos,UpdS s),	_,fs)		= (Just (pos,UpdS anyInput)  ,findState (nformid sid) fs world) 
										(upd,new,fs) 						= (Nothing, findState formid fs world)
		| otherwise = (Nothing, findState formid fs world)

		nformid sid = {formid & id = sid}

// specialize has to be used if a programmer want to specialize gForm
// it remembers the current value of the index in the expression and creates an editor to show this value
// the value might have been changed with this editor, so the value returned might differ form the value you started with !

specialize :: !(!(InIDataId a) !*HSt -> (!Form a,!*HSt)) !(InIDataId a) !*HSt -> (!Form a,!*HSt) | gUpd {|*|} a
specialize editor (init,formid) hst=:{cntr = inidx,states = formStates,world}
# nextidx = incrIndex inidx formid.ival		// this value will be repesented differently, so increment counter 
# (nv,{states,world}) 	= editor (init,nformid) {cntr = 0,states = formStates,world = world}
= (nv,{cntr=nextidx,states = states,world = world})
where
	nformid = {formid & id = formid.id +++ "_" +++ toString inidx}

	incrIndex :: Int v -> Int | gUpd {|*|} v
	incrIndex i v
	# (UpdSearch _ cnt,v) = gUpd {|*|} (UpdSearch (UpdI 0) -1) v
	= i + (-1 - cnt)

// gForm: automatic derives an Html Form for any Clean type

generic gForm a :: !(InIDataId a) !*HSt -> *(Form a, !*HSt)	

gForm{|Int|} (init,formid) hst 	
# (body,hst) = mkInput defsize (init,formid) (IV i) (UpdI i) hst
= ({changed=False, value=i, form=[body]},hst)
where
	i = formid.ival 
	
gForm{|Real|} (init,formid) hst 	
# (body,hst) = mkInput defsize (init,formid) (RV r) (UpdR r) hst
= ({changed=False, value=r, form=[body]},hst)
where
	r = formid.ival 

gForm{|Bool|} (init,formid) hst 	
# (body,hst) = mkInput defsize (init,formid) (BV b) (UpdB b) hst
= ({changed=False, value=b, form=[body]},hst)
where
	b = formid.ival 

gForm{|String|} (init,formid) hst 	
# (body,hst) = mkInput defsize (init,formid) (SV s) (UpdS s) hst
= ({changed=False, value=s, form=[body]},hst)
where
	s = formid.ival 

gForm{|UNIT|}  _ hst 
= ({changed=False, value=UNIT, form=[EmptyBody]},hst)

gForm{|PAIR|} gHa gHb (init,formid)  hst 
# (na,hst) = gHa (init,reuseFormId formid a) hst
# (nb,hst) = gHb (init,reuseFormId formid b) hst
= (	{changed=na.changed || nb.changed
	,value	=PAIR na.value nb.value
	,form	=[STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [na.form,nb.form]]
	},hst)
where
	(PAIR a b) = formid.ival 

gForm{|EITHER|} gHa gHb (init,formid)  hst 
= case formid.ival of
	(LEFT a)
	# (na,hst) = gHa (init,reuseFormId formid a) hst
	= ({changed=na.changed, value=LEFT na.value, form=na.form},hst)
	(RIGHT b)
	# (nb,hst) = gHb (init,reuseFormId formid b) hst
	= ({changed=nb.changed, value=RIGHT nb.value, form=nb.form},hst)

gForm{|OBJECT|} gHo (init,formid) hst
# (no,hst) = gHo (init,reuseFormId formid o) hst
= ({changed=no.changed, value=OBJECT no.value, form=no.form},hst)
where
	(OBJECT o) = formid.ival

gForm{|CONS of t|} gHc (init,formid) hst=:{cntr}
| not (isEmpty t.gcd_fields) 		 
	# (nc,hst) = gHc (init,reuseFormId formid c) (setCntr (cntr+1) hst) // don't display record constructor
	= ({changed=nc.changed, value=CONS nc.value, form=nc.form},hst)
| t.gcd_type_def.gtd_num_conses == 1 
	# (nc,hst) = gHc (init,reuseFormId formid c) (setCntr (cntr+1) hst) // don't display constructors that have no alternative
	= ({changed=nc.changed, value=CONS nc.value, form=nc.form},hst)
| t.gcd_name.[(size t.gcd_name) - 1] == '_' // don't display constructor names which end with an underscore
	# (nc,hst) = gHc (init,reuseFormId formid c) (setCntr (cntr+1) hst) 
	= ({changed=nc.changed, value=CONS nc.value, form=nc.form},hst)
# (selector,hst)= mkConsSelector formid t hst
# (nc,hst) = gHc (init,reuseFormId formid c) hst
= ({changed=nc.changed
	,value=CONS nc.value
	,form=[STable [Tbl_CellPadding (Pixels 0), Tbl_CellSpacing (Pixels 0)] [[selector,BodyTag nc.form]]]
	},hst)
where
	(CONS c) = formid.ival

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

	mkConsSel:: Int [String] Int (FormId x) -> BodyTag
	mkConsSel cntr list nr formid
		= Select 	[ Sel_Name ("CS")
					: styles
					]
					[Option  
						[Opt_Value (encodeTriplet (formid.id,cntr,UpdC elem))
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
						_		 ->	[ `Sel_Std	[Std_Style width, DisplayBoxStyle]
									,  Sel_Disabled Disabled
									]
			optionstyle	= case formid.mode of
							Edit	-> []
							_	 	-> [`Opt_Std [DisplayBoxStyle]]

			width = "width:" +++ (toString defpixel) +++ "px"

gForm{|FIELD of d |} gHx (init,formid) hst 
# (nx,hst) = gHx (init,reuseFormId formid x) hst
= ({changed=nx.changed
	,value=FIELD nx.value
	,form=[STable [Tbl_CellPadding (Pixels 1), Tbl_CellSpacing (Pixels 1)] [[fieldname,BodyTag nx.form]]]
	},hst)
where
	(FIELD x) = formid.ival
						
	fieldname =Input 	[	Inp_Type Inp_Text
						, 	Inp_Value (SV (prettyfy d.gfd_name +++ ": "))
						,	Inp_ReadOnly ReadOnly
						, 	`Inp_Std [DisplayBoxStyle]
						,	Inp_Size maxsize`
						] ""

	prettyfy name = mkString [toUpper lname : addspace lnames]
	where
		[lname:lnames] = mkList name
		addspace [] = []
		addspace [c:cs]
		| isUpper c	= [' ',toLower c:addspace cs]
		| otherwise = [c:addspace cs]
		
	maxsize` = ndefsize maxsize defsize
	maxsize = takemax defsize [toInt (toReal (size (prettyfy gfd_name)) * 0.8)  \\ {gfd_name} <- d.gfd_cons.gcd_fields]
	
	takemax i [] = i
	takemax i [j:js] 
	| i > j = takemax i js
	| otherwise = takemax j js

	ndefsize max def
	| max - def <= 0 = def
	| otherwise = ndefsize max (def + defsize)

gForm{|(->)|} garg gres (init,formid) hst 	
= ({changed=False, value=formid.ival, form=[]},hst)

// gUpd calculates a new value given the current value and a change in the value
// if necessary it invents new default value (e.g. when switching from Nil to Cons ...
// and leaves the rest untouched

:: UpdMode	= UpdSearch UpdValue Int		// search for indicated postion and update it
			| UpdCreate [ConsPos]			// create new values if necessary
			| UpdDone						// and just copy the remaining stuff

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

gUpd{|OBJECT|} gUpdo (UpdCreate l) _ 		// invent new type
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

gUpd{|FIELD|} gUpdx (UpdCreate l) _  // invent new type 
# (mode,x) = gUpdx (UpdCreate l) (abort "value of field evaluated")
= (mode,FIELD x)
gUpd{|FIELD|} gUpdx mode (FIELD x)  // other casesr
# (mode,x) = gUpdx mode x
= (mode,FIELD x)

gUpd{|(->)|} gUpdArg gUpdRes mode f = (mode,f)	

// small utility functions

mkInput :: !Int !(InIDataId d) Value UpdValue *HSt -> (BodyTag,*HSt) 
mkInput size (init,formid=:{mode = Edit}) val updval hst=:{cntr} 
	= ( Input 	[	Inp_Type Inp_Text
				, 	Inp_Value val
				,	Inp_Name (encodeTriplet (formid.id,cntr,updval))
				,	Inp_Size size
				, 	`Inp_Std [EditBoxStyle, Std_Title (showType val)]
				,	`Inp_Events	[OnChange callClean]
				] ""
		,setCntr (cntr+1) hst)
where
	showType (SV str) 	= "::String"
	showType (NQV str)	= "::String"
	showType (IV i)		= "::Int"
	showType (RV r) 	= "::Real"
	showType (BV b) 	= "::Bool"
mkInput size (init,{mode = Display}) val _ hst=:{cntr} 
	= ( Input 	[	Inp_Type Inp_Text
				, 	Inp_Value val
				,	Inp_ReadOnly ReadOnly
				, 	`Inp_Std [DisplayBoxStyle]
				,	Inp_Size size
				] ""
		,setCntr (cntr+1) hst)
mkInput size (init,_) val _ hst=:{cntr} 
	= ( EmptyBody,setCntr (cntr+1) hst)
		
toHtml :: a -> BodyTag | gForm {|*|} a
toHtml a 
# (na,_) = gForm{|*|} (Set,{id = "__toHtml", lifespan = Page, mode = Display, storage = PlainString, ival = a}) {cntr = 0, states = emptyFormStates, world = undef}
= BodyTag na.form

toHtmlForm :: (*HSt -> *(Form a,*HSt)) -> [BodyTag] | gForm{|*|}, gUpd{|*|}, gPrint{|*|}, gParse{|*|}, TC a
toHtmlForm anyform 
# (na,hst) = anyform {cntr = 0, states = emptyFormStates, world = undef}
=  na.form

toBody :: (Form a) -> BodyTag
toBody form = BodyTag form.form

createDefault :: a | gUpd{|*|} a 
createDefault = hd (mkNewList [])
where
	mkNewList _ = snd (gUpd {|*|} (UpdSearch (UpdC "_Cons") 0) [])	// generates a new list with one element of required type
derive gUpd []

setCntr :: InputId *HSt -> *HSt
setCntr i hst = {hst & cntr = i}

incrHSt :: Int *HSt -> *HSt
incrHSt i hst = {hst & cntr = i}

CntrHSt :: *HSt -> (Int,*HSt)
CntrHSt hst=:{cntr} = (cntr,hst)

getChangedId	:: !*HSt -> (String,!*HSt)	// id of form that has been changed by user
getChangedId hst=:{states}
# (id,states) = getUpdateId states
= (id,{hst & states = states })

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

// General access to the World environment on HSt:

appWorldHSt :: !.(*World -> *World) !*HSt -> *HSt
appWorldHSt f hst=:{world}
	= {hst & world=appWorldNWorld f world}

accWorldHSt :: !.(*World -> *(.a,*World)) !*HSt -> (.a,!*HSt)
accWorldHSt f hst=:{world}
	# (a,world)	= accWorldNWorld f world
	= (a,{hst & world=world})

// test interface

runUserApplication :: .(*HSt -> *(.a,*HSt)) *FormStates *NWorld -> *(.a,*FormStates,*NWorld)
runUserApplication userpage states nworld
# (html,{states,world}) 
	= userpage {cntr = 0, states = states, world = nworld}
= (html,states,world)

// Experimental testing stuf ...

instance toString (a,b,c) | toString a & toString b & toString c
where
	toString (a,b,c) = "(\"" +++ toString a +++ "\"," +++ toString b +++ "," +++ toString c +++ ")"
instance toString UpdValue
where
	toString (UpdI i)	= "UpdI " +++ toString i	
	toString (UpdR r)	= "UpdR " +++ toString r	
	toString (UpdB b)	= "UpdB " +++ toString b	
	toString (UpdC c)	= "UpdC " +++ c	
	toString (UpdS s)	= "UpdS \"" +++ s +++ "\""	

import MersenneTwister

randomTest :: !Int !(*HSt -> (Html,!*HSt)) *World -> ([(Triplet,UpdValue)],*World)
randomTest n userpage world 
# (inout,world) 		= stdio world						// open stdin and stdout channels
# nworld 				= {worldC = world, inout = inout}	
= doTest Nothing [] n (genRandInt 13) nworld
where
	doTest events eventsofar 0 _ nworld = (eventsofar,nworld.worldC)
	doTest events eventsofar n [r:rx] nworld 
	# (options,state,nworld) = doHtmlTest2 events userpage nworld
	# (triplet,update) = calcnewevent (options!!(abs r rem length options))
	= case options of
		[] 		= (eventsofar,nworld.worldC)
		list 	= doTest (Just (triplet,update,state)) [(triplet,update):eventsofar] (n-1) rx nworld
	where
		calcnewevent :: (InputType,Value,Maybe Triplet) -> (Triplet,UpdValue)
		calcnewevent (Inp_Button,SV buttonname,Just triplet) = (triplet,UpdS buttonname)		// button pressed
		calcnewevent (Inp_Text,IV oldint,Just triplet) 		 = (triplet,UpdI (oldint + 1))		// new 
		calcnewevent (Inp_Text,RV oldreal,Just triplet) 	 = (triplet,UpdR (oldreal + 1.0))
		calcnewevent (Inp_Text,BV oldbool,Just triplet) 	 = (triplet,UpdB (not oldbool))

doHtmlTest :: (Maybe *TestEvent) (*HSt -> (Html,!*HSt)) *World -> ([(InputType,Value,Maybe Triplet)],*FormStates,*World) // use this for testing
doHtmlTest nextevent userpage world // execute user code given the chosen testevent to determine the new possible inputs
# (inout,world) 				= stdio world						// open stdin and stdout channels
# nworld 						= {worldC = world, inout = inout}	
# (nextinputs,states,nworld) 	= doHtmlTest2 nextevent userpage nworld
= (nextinputs,states,nworld.worldC)

doHtmlTest2 :: (Maybe *TestEvent) (*HSt -> (Html,!*HSt)) *NWorld -> ([(InputType,Value,Maybe Triplet)],*FormStates,*NWorld)
doHtmlTest2 nextevent userpage nworld // execute user code given the chosen testevent to determine the new possible inputs
# (newstates,nworld) 	= case nextevent of 
							Nothing -> initTestFormStates nworld // initial empty states
							Just (triplet=:(id,pos,UpdI oldint),UpdI newint,oldstates) -> setTestFormStates (Just triplet) id (toString newint) oldstates nworld  
							Just (triplet=:(id,pos,UpdR oldreal),UpdR newreal,oldstates) -> setTestFormStates (Just triplet) id (toString newreal) oldstates nworld  
							Just (triplet=:(id,pos,UpdB oldbool),UpdB newbool,oldstates) -> setTestFormStates (Just triplet) id (toString newbool) oldstates nworld  
							Just (triplet=:(id,pos,UpdC oldcons),UpdC newcons,oldstates) -> setTestFormStates (Just triplet) id (toString newcons) oldstates nworld  
							Just (triplet=:(id,pos,UpdS oldstring),UpdS newstring,oldstates) -> setTestFormStates (Just triplet) id (toString newstring) oldstates nworld  
= runUserApplication userpage newstates nworld
where
	runUserApplication userpage states nworld
	# (Html (Head headattr headtags) (Body attr bodytags),{states,world}) 
						= userpage {cntr = 0, states = states, world = nworld}
	# options = fetchInputOptions bodytags
	= (options,states,world)
	
	fetchInputOptions :: [BodyTag] -> [(InputType,Value,Maybe (String,Int,UpdValue))] // determine from html code which inputs can be given next time
	fetchInputOptions [] 						= []
	fetchInputOptions [Input info _  :inputs]	= fetchInputOption info   ++ fetchInputOptions inputs
	fetchInputOptions [BodyTag bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [A _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dd _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dir _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Div _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dl _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dt _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Fieldset _ bdtag :inputs]= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Font _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Form _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Li _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Map _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Menu _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Ol _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [P _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Pre _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Span _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Table _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [TBody _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Td _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [TFoot _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [THead _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Tr _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Ul _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [STable _ bdtags :inputs] = flatten (map fetchInputOptions bdtags) ++ fetchInputOptions inputs
	fetchInputOptions [_			 :inputs] 	= fetchInputOptions inputs
	
	fetchInputOption [Inp_Type inptype, Inp_Value val,	Inp_Name triplet:_] = [(inptype,val,decodeInfo triplet)]
	fetchInputOption [Inp_Type inptype, Inp_Value val:_] = [(inptype,val,Nothing)]
	fetchInputOption [x:xs] = fetchInputOption xs
	fetchInputOption _ = []


doHtmlTest3 :: (Maybe *TestEvent) (*HSt -> (Html,!*HSt)) *NWorld -> (Html,*FormStates,*NWorld)
doHtmlTest3 nextevent userpage nworld // execute user code given the chosen testevent to determine the new possible inputs
# (newstates,nworld) 	= case nextevent of 
							Nothing -> initTestFormStates nworld // initial empty states
							Just (triplet=:(id,pos,UpdI oldint),UpdI newint,oldstates) -> setTestFormStates (Just triplet) id (toString newint) oldstates nworld  
							Just (triplet=:(id,pos,UpdR oldreal),UpdR newreal,oldstates) -> setTestFormStates (Just triplet) id (toString newreal) oldstates nworld  
							Just (triplet=:(id,pos,UpdB oldbool),UpdB newbool,oldstates) -> setTestFormStates (Just triplet) id (toString newbool) oldstates nworld  
							Just (triplet=:(id,pos,UpdC oldcons),UpdC newcons,oldstates) -> setTestFormStates (Just triplet) id (toString newcons) oldstates nworld  
							Just (triplet=:(id,pos,UpdS oldstring),UpdS newstring,oldstates) -> setTestFormStates (Just triplet) id (toString newstring) oldstates nworld  
= runUserApplication userpage newstates nworld
where
	runUserApplication userpage states nworld
	# (html,{states,world}) 
						= userpage {cntr = 0, states = states, world = nworld}
	= (html,states,world)
	
fetchInputOptions1 :: Html -> [(InputType,Value,Maybe (String,Int,UpdValue))] // determine from html code which inputs can be given next time
fetchInputOptions1 (Html (Head headattr headtags) (Body attr bodytags))
	= fetchInputOptions bodytags
where
	fetchInputOptions :: [BodyTag] -> [(InputType,Value,Maybe (String,Int,UpdValue))] // determine from html code which inputs can be given next time
	fetchInputOptions [] 						= []
	fetchInputOptions [Input info _  :inputs]	= fetchInputOption info   ++ fetchInputOptions inputs
	fetchInputOptions [BodyTag bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [A _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dd _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dir _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Div _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dl _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Dt _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Fieldset _ bdtag :inputs]= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Font _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Form _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Li _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Map _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Menu _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Ol _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [P _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Pre _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Span _ bdtag  :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Table _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [TBody _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Td _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [TFoot _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [THead _ bdtag :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Tr _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [Ul _ bdtag 	 :inputs] 	= fetchInputOptions bdtag ++ fetchInputOptions inputs
	fetchInputOptions [STable _ bdtags :inputs] = flatten (map fetchInputOptions bdtags) ++ fetchInputOptions inputs
	fetchInputOptions [_			 :inputs] 	= fetchInputOptions inputs
	
	fetchInputOption [Inp_Type inptype, Inp_Value val,	Inp_Name triplet:_] = [(inptype,val,decodeInfo triplet)]
	fetchInputOption [Inp_Type inptype, Inp_Value val:_] = [(inptype,val,Nothing)]
	fetchInputOption [x:xs] = fetchInputOption xs
	fetchInputOption _ = []

findTexts :: Html -> [String]
findTexts (Html (Head headattr headtags) (Body attr bodytags))
 = ft bodytags []
where
	ft :: [BodyTag] [String] -> [String]
	ft [A		attrs btags:tl] c = ft btags (ft tl c)	// link ancor <a></a>
	ft [B  		attrs str  :tl] c = [str:ft tl c]		// bold <b></b>
	ft [Big  	attrs str  :tl] c = [str:ft tl c]		// big text <big></big>
	ft [Caption	attrs str  :tl] c = [str:ft tl c]		// Table caption <caption></caption>			
	ft [Center	attrs str  :tl] c = [str:ft tl c]		// centered text <center></center>			
	ft [Code	attrs str  :tl] c = [str:ft tl c] 		// computer code text <code></code>			
	ft [Em		attrs str  :tl] c = [str:ft tl c] 		// emphasized text <em></em>			
	ft [H1	 	attrs str  :tl] c = [str:ft tl c]		// header 1 <h1></h1>
	ft [H2 		attrs str  :tl] c = [str:ft tl c]		// header 2 <h2></h2>
	ft [H3 		attrs str  :tl] c = [str:ft tl c]		// header 3 <h3></h3>
	ft [H4	 	attrs str  :tl] c = [str:ft tl c]		// header 4 <h4></h4>
	ft [H5 		attrs str  :tl] c = [str:ft tl c]		// header 5 <h5></h5>
	ft [H6 		attrs str  :tl] c = [str:ft tl c]		// header 6 <h6></h6>			
	ft [I 		attrs str  :tl] c = [str:ft tl c]		// italic text <i></i>
	ft [Table	attrs btags:tl] c = ft btags (ft tl c)	// table <table></table>
	ft [TBody 	attrs btags:tl] c = ft btags (ft tl c)	// body of a table <tbody></tbody>
	ft [Td		attrs btags:tl] c = ft btags (ft tl c)	// table cell <td></td>
	ft [Tr		attrs btags:tl] c = ft btags (ft tl c)	// table row <tr></tr>
	ft [Tt		attrs str  :tl] c = [str:ft tl c] 		// teletyped text <tt></tt>
	ft [Txt		      str  :tl] c = [str:ft tl c] 		// plain text
	ft [U		attrs str  :tl] c = [str:ft tl c]		// underlined text <u></u>
	ft [_:tl]                   c = ft tl c
	ft []                       c = c

