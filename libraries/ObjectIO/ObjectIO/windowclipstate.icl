implementation module windowclipstate


//	Clean Object I/O library, version 1.2


import	StdBool, StdList, StdMisc
import	osrgn, oswindow
import	commondef, wstate
from	windowaccess	import getWItemRadioInfo,  getWItemCheckInfo,  getWItemCompoundInfo, getWindowInfoWindowData,
								getCompoundContentRect, getCompoundHScrollRect, getCompoundVScrollRect, getWindowContentRect
from	wstateaccess	import getWItemRadioInfo`, getWItemCheckInfo`, getWItemCompoundInfo`


/*	createClipState wMetrics allClipStates validate wPtr clipRect defId isVisible items
		calculates the ClipState that corresponds with items.
		If the Boolean argument is True, also the invalid ClipStates are recalculated of CompoundControls
			that are inside the window frame. 
*/
createClipState :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !Bool ![WElementHandle .ls .pst] !*OSToolbox
																	  -> (!ClipState,![WElementHandle .ls .pst],!*OSToolbox)
createClipState wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs tb
	# (clipRgn,tb)			= osnewrectrgn clipRect tb
	# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
	= ({clipRgn=clipRgn,clipOk=True},itemHs,tb)
where
	createWElementsClipState :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !Bool ![WElementHandle .ls .pst] !OSRgnHandle !*OSToolbox
																							  -> (![WElementHandle .ls .pst],!OSRgnHandle,!*OSToolbox)
	createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId isVisible [itemH:itemHs] clipRgn tb
		# (itemH, clipRgn,tb)	= createWElementClipState  wMetrics allClipStates validate wPtr clipRect defId isVisible itemH  clipRgn tb
		# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
		= ([itemH:itemHs],clipRgn,tb)
	where
		createWElementClipState :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !Bool !(WElementHandle .ls .pst) !OSRgnHandle !*OSToolbox
																								  -> (!WElementHandle .ls .pst, !OSRgnHandle,!*OSToolbox)
		createWElementClipState wMetrics allClipStates validate wPtr clipRect defId isVisible (WItemHandle itemH=:{wItemShow,wItemKind,wItemPos,wItemSize}) clipRgn tb
			| not itemVisible || DisjointRects clipRect (PosSizeToRect wItemPos wItemSize)
				| not allClipStates || not (isRecursiveControl wItemKind)	// PA:<>IsCompoundControl
					= (WItemHandle itemH,clipRgn,tb)
				| wItemKind==IsLayoutControl								// PA: this alternative added
					# clipRect				= PosSizeToRect wItemPos wItemSize
					# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId False itemH.wItems clipRgn tb
					# itemH					= {itemH & wItems=itemHs}
					= (WItemHandle itemH,clipRgn,tb)
				| validate
					# (itemH,tb)			= validateCompoundClipState wMetrics allClipStates wPtr defId itemVisible itemH tb
					= (WItemHandle itemH,clipRgn,tb)
				// otherwise
					# (itemH,tb)			= forceValidCompoundClipState wMetrics allClipStates wPtr defId itemVisible itemH tb
					= (WItemHandle itemH,clipRgn,tb)
			| otherwise
				# (itemH,clipRgn,tb)		= createWItemClipState wMetrics allClipStates validate wPtr clipRect defId itemH clipRgn tb
				= (WItemHandle itemH,clipRgn,tb)
		where
			itemVisible						= isVisible && wItemShow
			
			createWItemClipState :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !(WItemHandle .ls .pst) !OSRgnHandle !*OSToolbox
																							 -> (!WItemHandle .ls .pst, !OSRgnHandle,!*OSToolbox)
			createWItemClipState _ _ _ wPtr clipRect _ itemH=:{wItemKind=IsRadioControl,wItemInfo} clipRgn tb
				# (clipRgn,tb)	= StateMap2 (createRadioClipState wPtr clipRect) (getWItemRadioInfo wItemInfo).radioItems (clipRgn,tb)
				= (itemH,clipRgn,tb)
			where
				createRadioClipState :: !OSWindowPtr !Rect !(RadioItemInfo .pst) !(!OSRgnHandle,!*OSToolbox) -> (!OSRgnHandle,!*OSToolbox)
				createRadioClipState wPtr clipRect {radioItemPos,radioItemSize} (clipRgn,tb)
					# (radioRgn,tb)	= OSclipRadioControl wPtr (0,0) clipRect (toTuple radioItemPos) (toTuple radioItemSize) tb
					# (diffRgn, tb)	= osdiffrgn clipRgn radioRgn tb
					# tb			= osdisposergn clipRgn tb
					# tb			= osdisposergn radioRgn tb
					= (diffRgn,tb)
			
			createWItemClipState _ _ _ wPtr clipRect defId itemH=:{wItemKind=IsCheckControl,wItemInfo} clipRgn tb
				# (clipRgn,tb)	= StateMap2 (createCheckClipState wPtr clipRect) (getWItemCheckInfo wItemInfo).checkItems (clipRgn,tb)
				= (itemH,clipRgn,tb)
			where
				createCheckClipState :: !OSWindowPtr !Rect !(CheckItemInfo .pst) !(!OSRgnHandle,!*OSToolbox) -> (!OSRgnHandle,!*OSToolbox)
				createCheckClipState wPtr clipRect {checkItemPos,checkItemSize} (clipRgn,tb)
					# (checkRgn,tb)	= OSclipCheckControl wPtr (0,0) clipRect (toTuple checkItemPos) (toTuple checkItemSize) tb
					# (diffRgn, tb)	= osdiffrgn clipRgn checkRgn tb
					# tb			= osdisposergn clipRgn tb
					# tb			= osdisposergn checkRgn tb
					= (diffRgn,tb)
			
			createWItemClipState wMetrics allClipStates validate wPtr clipRect defId itemH=:{wItemKind=IsCompoundControl,wItems} clipRgn tb
				# (rectRgn,tb)			= OSclipCompoundControl wPtr (0,0) clipRect (toTuple itemPos) (toTuple itemSize) tb
				# (diffRgn,tb)			= osdiffrgn clipRgn rectRgn tb
				# tb					= osdisposergn clipRgn tb
				# tb					= osdisposergn rectRgn tb
				| allClipStates
					| validate
						# (itemH,tb)	= validateCompoundClipState wMetrics allClipStates wPtr defId True itemH tb
						= (itemH,diffRgn,tb)
					// otherwise
						# (itemH,tb)	= forceValidCompoundClipState wMetrics allClipStates wPtr defId True itemH tb
						= (itemH,diffRgn,tb)
				| otherwise
					= (itemH,diffRgn,tb)
			where
				itemPos					= itemH.wItemPos
				itemSize				= itemH.wItemSize
			
			createWItemClipState wMetrics allClipStates validate wPtr clipRect defId itemH=:{wItemKind=IsLayoutControl,wItems} clipRgn tb
				# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect1 defId True wItems clipRgn tb
				= ({itemH & wItems=itemHs},clipRgn,tb)
			where
				clipRect1				= IntersectRects (PosSizeToRect itemH.wItemPos itemH.wItemSize) clipRect
			
			createWItemClipState _ _ _ wPtr clipRect defId itemH=:{wItemKind,wItemPos,wItemSize} clipRgn tb
				| okItem
					# (itemRgn,tb)		= clipItem wPtr (0,0) clipRect (toTuple wItemPos) (toTuple wItemSize) tb
					# (diffRgn,tb)		= osdiffrgn clipRgn itemRgn tb
					# tb				= osdisposergn clipRgn tb
					# tb				= osdisposergn itemRgn tb
					= (itemH,diffRgn,tb)
			where
				(okItem,clipItem)		= case wItemKind of
											IsPopUpControl			-> (True,OSclipPopUpControl)
											IsSliderControl			-> (True,OSclipSliderControl)
											IsTextControl			-> (True,OSclipTextControl)
											IsEditControl			-> (True,OSclipEditControl)
											IsButtonControl			-> (True,OSclipButtonControl)
											IsCustomButtonControl	-> (True,OSclipCustomButtonControl)
											IsCustomControl			-> (True,OSclipCustomControl)
											_						-> (False,undef)
				
			createWItemClipState _ _ _ _ _ _ itemH clipRgn tb
				= (itemH,clipRgn,tb)
		
		createWElementClipState wMetrics allClipStates validate wPtr clipRect defId isVisible (WListLSHandle itemHs) clipRgn tb
			# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
			= (WListLSHandle itemHs,clipRgn,tb)
		
		createWElementClipState wMetrics allClipStates validate wPtr clipRect defId isVisible (WExtendLSHandle wExH=:{wExtendItems=itemHs}) clipRgn tb
			# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
			= (WExtendLSHandle {wExH & wExtendItems=itemHs},clipRgn,tb)
		
		createWElementClipState wMetrics allClipStates validate wPtr clipRect defId isVisible (WChangeLSHandle wChH=:{wChangeItems=itemHs}) clipRgn tb
			# (itemHs,clipRgn,tb)	= createWElementsClipState wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
			= (WChangeLSHandle {wChH & wChangeItems=itemHs},clipRgn,tb)
	
	createWElementsClipState _ _ _ _ _ _ _ itemHs clipRgn tb
		= (itemHs,clipRgn,tb)


createClipState` :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !Bool ![WElementHandle`] !*OSToolbox
																	   -> (!ClipState,![WElementHandle`],!*OSToolbox)
createClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs tb
	# (clipRgn,tb)			= osnewrectrgn clipRect tb
	# (itemHs,clipRgn,tb)	= createWElementsClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
	= ({clipRgn=clipRgn,clipOk=True},itemHs,tb)
where
	createWElementsClipState` :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !Bool ![WElementHandle`] !OSRgnHandle !*OSToolbox
																							   -> (![WElementHandle`],!OSRgnHandle,!*OSToolbox)
	createWElementsClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible [itemH:itemHs] clipRgn tb
		# (itemH, clipRgn,tb)	= createWElementClipState`  wMetrics allClipStates validate wPtr clipRect defId isVisible itemH  clipRgn tb
		# (itemHs,clipRgn,tb)	= createWElementsClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
		= ([itemH:itemHs],clipRgn,tb)
	where
		createWElementClipState` :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !Bool !WElementHandle` !OSRgnHandle !*OSToolbox
																								  -> (!WElementHandle`,!OSRgnHandle,!*OSToolbox)
		createWElementClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible (WItemHandle` itemH=:{wItemShow`,wItemKind`,wItemPos`,wItemSize`}) clipRgn tb
			| not itemVisible || DisjointRects clipRect (PosSizeToRect wItemPos` wItemSize`)
				| not allClipStates || not (isRecursiveControl wItemKind`)	// PA:<>IsCompoundControl
					= (WItemHandle` itemH,clipRgn,tb)
				| wItemKind`==IsLayoutControl								// PA: this alternative added
					# clipRect				= PosSizeToRect wItemPos` wItemSize`
					# (itemHs,clipRgn,tb)	= createWElementsClipState` wMetrics allClipStates validate wPtr clipRect defId False itemH.wItems` clipRgn tb
					# itemH					= {itemH & wItems`=itemHs}
					= (WItemHandle` itemH,clipRgn,tb)
				| validate
					# (itemH,tb)			= validateCompoundClipState` wMetrics allClipStates wPtr defId itemVisible itemH tb
					= (WItemHandle` itemH,clipRgn,tb)
				// otherwise
					# (itemH,tb)			= forceValidCompoundClipState` wMetrics allClipStates wPtr defId itemVisible itemH tb
					= (WItemHandle` itemH,clipRgn,tb)
			| otherwise
				# (itemH,clipRgn,tb)		= createWItemClipState` wMetrics allClipStates validate wPtr clipRect defId itemH clipRgn tb
				= (WItemHandle` itemH,clipRgn,tb)
		where
			itemVisible						= isVisible && wItemShow`
			
			createWItemClipState` :: !OSWindowMetrics !Bool !Bool !OSWindowPtr !Rect !(Maybe Id) !WItemHandle` !OSRgnHandle !*OSToolbox
																							 -> (!WItemHandle`,!OSRgnHandle,!*OSToolbox)
			createWItemClipState` _ _ _ wPtr clipRect _ itemH=:{wItemKind`=IsRadioControl,wItemInfo`} clipRgn tb
				# (clipRgn,tb)		= StateMap2 (createRadioClipState` wPtr clipRect) (getWItemRadioInfo` wItemInfo`).radioItems` (clipRgn,tb)
				= (itemH,clipRgn,tb)
			where
				createRadioClipState` :: !OSWindowPtr !Rect !RadioItemInfo` !(!OSRgnHandle,!*OSToolbox) -> (!OSRgnHandle,!*OSToolbox)
				createRadioClipState` wPtr clipRect {radioItemPos`,radioItemSize`} (clipRgn,tb)
					# (radioRgn,tb)	= OSclipRadioControl wPtr (0,0) clipRect (toTuple radioItemPos`) (toTuple radioItemSize`) tb
					# (diffRgn, tb)	= osdiffrgn clipRgn radioRgn tb
					# tb			= osdisposergn clipRgn tb
					# tb			= osdisposergn radioRgn tb
					= (diffRgn,tb)
			
			createWItemClipState` _ _ _ wPtr clipRect defId itemH=:{wItemKind`=IsCheckControl,wItemInfo`} clipRgn tb
				# (clipRgn,tb)		= StateMap2 (createCheckClipState` wPtr clipRect) (getWItemCheckInfo` wItemInfo`).checkItems` (clipRgn,tb)
				= (itemH,clipRgn,tb)
			where
				createCheckClipState` :: !OSWindowPtr !Rect !CheckItemInfo` !(!OSRgnHandle,!*OSToolbox) -> (!OSRgnHandle,!*OSToolbox)
				createCheckClipState` wPtr clipRect {checkItemPos`,checkItemSize`} (clipRgn,tb)
					# (checkRgn,tb)	= OSclipCheckControl wPtr (0,0) clipRect (toTuple checkItemPos`) (toTuple checkItemSize`) tb
					# (diffRgn, tb)	= osdiffrgn clipRgn checkRgn tb
					# tb			= osdisposergn clipRgn tb
					# tb			= osdisposergn checkRgn tb
					= (diffRgn,tb)
			
			createWItemClipState` wMetrics allClipStates validate wPtr clipRect defId itemH=:{wItemKind`=IsCompoundControl,wItems`} clipRgn tb
				# (rectRgn,tb)				= OSclipCompoundControl wPtr (0,0) clipRect (toTuple itemPos) (toTuple itemSize) tb
				# (diffRgn,tb)				= osdiffrgn clipRgn rectRgn tb
				# tb						= osdisposergn clipRgn tb
				# tb						= osdisposergn rectRgn tb
				| allClipStates
					| validate
						# (itemH,tb)		= validateCompoundClipState` wMetrics allClipStates wPtr defId True itemH tb
						= (itemH,diffRgn,tb)
					// otherwise
						# (itemH,tb)		= forceValidCompoundClipState` wMetrics allClipStates wPtr defId True itemH tb
						= (itemH,diffRgn,tb)
				| otherwise
					= (itemH,diffRgn,tb)
			where
				itemPos						= itemH.wItemPos`
				itemSize					= itemH.wItemSize`
			
			createWItemClipState` wMetrics allClipStates validate wPtr clipRect defId itemH=:{wItemKind`=IsLayoutControl,wItems`} clipRgn tb
				# (itemHs,clipRgn,tb)	= createWElementsClipState` wMetrics allClipStates validate wPtr clipRect1 defId True wItems` clipRgn tb
				= ({itemH & wItems`=itemHs},clipRgn,tb)
			where
				clipRect1				= IntersectRects (PosSizeToRect itemH.wItemPos` itemH.wItemSize`) clipRect
			
			createWItemClipState` _ _ _ wPtr clipRect defId itemH=:{wItemKind`,wItemPos`,wItemSize`} clipRgn tb
				| okItem
					# (itemRgn,tb)		= clipItem wPtr (0,0) clipRect (toTuple wItemPos`) (toTuple wItemSize`) tb
					# (diffRgn,tb)		= osdiffrgn clipRgn itemRgn tb
					# tb				= osdisposergn clipRgn tb
					# tb				= osdisposergn itemRgn tb
					= (itemH,diffRgn,tb)
			where
				(okItem,clipItem)		= case wItemKind` of
											IsPopUpControl			-> (True,OSclipPopUpControl)
											IsSliderControl			-> (True,OSclipSliderControl)
											IsTextControl			-> (True,OSclipTextControl)
											IsEditControl			-> (True,OSclipEditControl)
											IsButtonControl			-> (True,OSclipButtonControl)
											IsCustomButtonControl	-> (True,OSclipCustomButtonControl)
											IsCustomControl			-> (True,OSclipCustomControl)
											_						-> (False,undef)
				
			createWItemClipState` _ _ _ _ _ _ itemH clipRgn tb
				= (itemH,clipRgn,tb)
		
		createWElementClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible (WRecursiveHandle` itemHs wKind) clipRgn tb
			# (itemHs,clipRgn,tb)	= createWElementsClipState` wMetrics allClipStates validate wPtr clipRect defId isVisible itemHs clipRgn tb
			= (WRecursiveHandle` itemHs wKind,clipRgn,tb)
	
	createWElementsClipState` _ _ _ _ _ _ _ itemH clipRgn tb
		= (itemH,clipRgn,tb)

disposeClipState:: !ClipState !*OSToolbox -> *OSToolbox
disposeClipState {clipRgn} tb
	| clipRgn==0	= tb
	| otherwise		= osdisposergn clipRgn tb


/*	validateAllClipStates(`) validate wPtr defaultId isVisible items
		checks for all items if the ClipState of CompoundControls is valid.
		If validate holds, then the ClipState is checked, otherwise the ClipState is disposed and recalculated(!!).
*/
validateAllClipStates :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool ![WElementHandle .ls .pst] !*OSToolbox -> (![WElementHandle .ls .pst],!*OSToolbox)
validateAllClipStates wMetrics validate wPtr defaultId isVisible itemHs tb
	= StateMap (validateclipstate wMetrics validate wPtr defaultId isVisible) itemHs tb
where
	validateclipstate :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool !(WElementHandle .ls.pst) !*OSToolbox -> (!WElementHandle .ls .pst,!*OSToolbox)
	validateclipstate wMetrics validate wPtr defaultId isVisible (WItemHandle itemH=:{wItemKind}) tb
		| wItemKind<>IsCompoundControl
			| isRecursiveControl wItemKind	// PA: added for LayoutControls
				# (itemHs,tb)	= StateMap (validateclipstate wMetrics validate wPtr defaultId itemVisible) itemH.wItems tb
				= (WItemHandle {itemH & wItems=itemHs},tb)
			// otherwise
				= (WItemHandle itemH,tb)
		| validate
			# (itemH,tb)	= validateCompoundClipState wMetrics True wPtr defaultId itemVisible itemH tb
			= (WItemHandle itemH,tb)
		| otherwise
			# (itemH,tb)	= forceValidCompoundClipState wMetrics True wPtr defaultId itemVisible itemH tb
			= (WItemHandle itemH,tb)
	where
		itemVisible			= isVisible && itemH.wItemShow
	
	validateclipstate wMetrics validate wPtr defaultId isVisible (WListLSHandle itemHs) tb
		# (itemHs,tb)	= StateMap (validateclipstate wMetrics validate wPtr defaultId isVisible) itemHs tb
		= (WListLSHandle itemHs,tb)
	
	validateclipstate wMetrics validate wPtr defaultId isVisible (WExtendLSHandle wExH=:{wExtendItems=itemHs}) tb
		# (itemHs,tb)	= StateMap (validateclipstate wMetrics validate wPtr defaultId isVisible) itemHs tb
		= (WExtendLSHandle {wExH & wExtendItems=itemHs},tb)
	
	validateclipstate wMetrics validate wPtr defaultId isVisible (WChangeLSHandle wChH=:{wChangeItems=itemHs}) tb
		# (itemHs,tb)	= StateMap (validateclipstate wMetrics validate wPtr defaultId isVisible) itemHs tb
		= (WChangeLSHandle {wChH & wChangeItems=itemHs},tb)


validateAllClipStates` :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool ![WElementHandle`] !*OSToolbox -> (![WElementHandle`],!*OSToolbox)
validateAllClipStates` wMetrics validate wPtr defaultId isVisible itemHs tb
	= StateMap (validateclipstate wMetrics validate wPtr defaultId isVisible) itemHs tb
where
	validateclipstate :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool !WElementHandle` !*OSToolbox -> (!WElementHandle`,!*OSToolbox)
	validateclipstate wMetrics validate wPtr defaultId isVisible (WItemHandle` itemH=:{wItemKind`}) tb
		| wItemKind`<>IsCompoundControl
			| isRecursiveControl wItemKind`	// PA: added for LayoutControls
				# (itemHs,tb)	= StateMap (validateclipstate wMetrics validate wPtr defaultId itemVisible) itemH.wItems` tb
				= (WItemHandle` {itemH & wItems`=itemHs},tb)
			// otherwise
				= (WItemHandle` itemH,tb)
		| validate
			# (itemH,tb)	= validateCompoundClipState` wMetrics True wPtr defaultId itemVisible itemH tb
			= (WItemHandle` itemH,tb)
		| otherwise
			# (itemH,tb)	= forceValidCompoundClipState` wMetrics True wPtr defaultId itemVisible itemH tb
			= (WItemHandle` itemH,tb)
	where
		itemVisible			= isVisible && itemH.wItemShow`
	
	validateclipstate wMetrics validate wPtr defaultId isVisible (WRecursiveHandle` itemHs wKind) tb
		# (itemHs,tb)	= StateMap (validateclipstate wMetrics validate wPtr defaultId isVisible) itemHs tb
		= (WRecursiveHandle` itemHs wKind,tb)


validateWindowClipState :: !OSWindowMetrics !Bool !OSWindowPtr !(WindowHandle .ls .pst) !*OSToolbox -> (!WindowHandle .ls .pst,!*OSToolbox)
validateWindowClipState wMetrics allClipStates wPtr wH=:{whKind,whWindowInfo,whItems,whSize,whDefaultId,whShow} tb
	| whKind==IsGameWindow
		= (wH,tb)
	| whKind==IsDialog
		| not allClipStates
			= (wH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates wMetrics True wPtr whDefaultId whShow whItems tb
			= ({wH & whItems=itemHs},tb)
	| clipState.clipOk
		| not allClipStates
			= (wH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates wMetrics True wPtr whDefaultId whShow whItems tb
			= ({wH & whItems=itemHs},tb)
	| otherwise
		# tb					= disposeClipState clipState tb
		# (clipState,itemHs,tb)	= createClipState wMetrics allClipStates True wPtr contentRect whDefaultId whShow whItems tb
		  windowInfo			= {windowInfo & windowClip=clipState}
		= ({wH & whItems=itemHs,whWindowInfo=WindowInfo windowInfo},tb)
where
	windowInfo					= getWindowInfoWindowData whWindowInfo
	clipState					= windowInfo.windowClip
	domainRect					= windowInfo.windowDomain
	hasScrolls					= (isJust windowInfo.windowHScroll, isJust windowInfo.windowVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple whSize) hasScrolls
	contentRect					= getWindowContentRect wMetrics visScrolls (SizeToRect whSize)

validateWindowClipState` :: !OSWindowMetrics !Bool !OSWindowPtr !WindowHandle` !*OSToolbox -> (!WindowHandle`,!*OSToolbox)
validateWindowClipState` wMetrics allClipStates wPtr wH=:{whKind`,whWindowInfo`,whItems`,whSize`,whDefaultId`,whShow`} tb
	| whKind`==IsGameWindow
		= (wH,tb)
	| whKind`==IsDialog
		| not allClipStates
			= (wH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates` wMetrics True wPtr whDefaultId` whShow` whItems` tb
			= ({wH & whItems`=itemHs},tb)
	| clipState.clipOk
		| not allClipStates
			= (wH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates` wMetrics True wPtr whDefaultId` whShow` whItems` tb
			= ({wH & whItems`=itemHs},tb)
	| otherwise
		# tb					= disposeClipState clipState tb
		# (clipState,itemHs,tb)	= createClipState` wMetrics allClipStates True wPtr contentRect whDefaultId` whShow` whItems` tb
		  windowInfo			= {windowInfo & windowClip=clipState}
		= ({wH & whItems`=itemHs,whWindowInfo`=WindowInfo windowInfo},tb)
where
	windowInfo					= getWindowInfoWindowData whWindowInfo`
	clipState					= windowInfo.windowClip
	domainRect					= windowInfo.windowDomain
	hasScrolls					= (isJust windowInfo.windowHScroll, isJust windowInfo.windowVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple whSize`) hasScrolls
	contentRect					= getWindowContentRect wMetrics visScrolls (SizeToRect whSize`)

forceValidWindowClipState :: !OSWindowMetrics !Bool !OSWindowPtr !(WindowHandle .ls .pst) !*OSToolbox -> (!WindowHandle .ls .pst,!*OSToolbox)
forceValidWindowClipState wMetrics allClipStates wPtr wH=:{whKind,whWindowInfo,whItems,whSize,whDefaultId,whShow} tb
	| whKind==IsGameWindow
		= (wH,tb)
	| whKind==IsDialog
		| not allClipStates
			= (wH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates wMetrics False wPtr whDefaultId whShow whItems tb
			= ({wH & whItems=itemHs},tb)
	| otherwise
		# tb					= disposeClipState clipState tb
		# (clipState,itemHs,tb)	= createClipState wMetrics allClipStates False wPtr contentRect whDefaultId whShow whItems tb
		  windowInfo			= {windowInfo & windowClip=clipState}
		= ({wH & whItems=itemHs,whWindowInfo=WindowInfo windowInfo},tb)
where
	windowInfo					= getWindowInfoWindowData whWindowInfo
	clipState					= windowInfo.windowClip
	domainRect					= windowInfo.windowDomain
	hasScrolls					= (isJust windowInfo.windowHScroll, isJust windowInfo.windowVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple whSize) hasScrolls
	contentRect					= getWindowContentRect wMetrics visScrolls (SizeToRect whSize)

forceValidWindowClipState` :: !OSWindowMetrics !Bool !OSWindowPtr !WindowHandle` !*OSToolbox -> (!WindowHandle`,!*OSToolbox)
forceValidWindowClipState` wMetrics allClipStates wPtr wH=:{whKind`,whWindowInfo`,whItems`,whSize`,whDefaultId`,whShow`} tb
	| whKind`==IsGameWindow
		= (wH,tb)
	| whKind`==IsDialog
		| not allClipStates
			= (wH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates` wMetrics False wPtr whDefaultId` whShow` whItems` tb
			= ({wH & whItems`=itemHs},tb)
	| otherwise
		# tb					= disposeClipState clipState tb
		# (clipState,itemHs,tb)	= createClipState` wMetrics allClipStates False wPtr contentRect whDefaultId` whShow` whItems` tb
		  windowInfo			= {windowInfo & windowClip=clipState}
		= ({wH & whItems`=itemHs,whWindowInfo`=WindowInfo windowInfo},tb)
where
	windowInfo					= getWindowInfoWindowData whWindowInfo`
	clipState					= windowInfo.windowClip
	domainRect					= windowInfo.windowDomain
	hasScrolls					= (isJust windowInfo.windowHScroll, isJust windowInfo.windowVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple whSize`) hasScrolls
	contentRect					= getWindowContentRect wMetrics visScrolls (SizeToRect whSize`)


invalidateWindowClipState :: !(WindowHandle .ls .pst) -> WindowHandle .ls .pst
invalidateWindowClipState wH=:{whKind,whWindowInfo}
	| whKind==IsWindow
		# windowInfo	= getWindowInfoWindowData whWindowInfo
		  clipState		= windowInfo.windowClip
		= {wH & whWindowInfo=WindowInfo {windowInfo & windowClip={clipState & clipOk=False}}}
	| otherwise
		= wH

invalidateWindowClipState` :: !WindowHandle` -> WindowHandle`
invalidateWindowClipState` wH=:{whKind`,whWindowInfo`}
	| whKind`==IsWindow
		# windowInfo	= getWindowInfoWindowData whWindowInfo`
		  clipState		= windowInfo.windowClip
		= {wH & whWindowInfo`=WindowInfo {windowInfo & windowClip={clipState & clipOk=False}}}
	| otherwise
		= wH


validateCompoundClipState :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool !(WItemHandle .ls .pst) !*OSToolbox -> (!WItemHandle .ls .pst,!*OSToolbox)
validateCompoundClipState wMetrics allClipStates wPtr defId isVisible itemH=:{wItemShow,wItemPos,wItemSize,wItemInfo,wItems} tb
	| clipState.clipOk
		| not allClipStates
			= (itemH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates wMetrics True wPtr defId itemVisible wItems tb
			= ({itemH & wItems=itemHs},tb)
	| otherwise
		# tb					= disposeClipState clipState tb
		# (clipState,itemHs,tb)	= createClipState wMetrics allClipStates True wPtr contentRect defId itemVisible wItems tb
		  compoundInfo			= {compoundInfo & compoundLookInfo={compoundLook & compoundClip=clipState}}
		= ({itemH & wItemInfo=CompoundInfo compoundInfo,wItems=itemHs},tb)
where
	itemVisible					= isVisible && wItemShow
	compoundInfo				= getWItemCompoundInfo wItemInfo
	compoundLook				= compoundInfo.compoundLookInfo
	clipState					= compoundLook.compoundClip
	domainRect					= compoundInfo.compoundDomain
	hasScrolls					= (isJust compoundInfo.compoundHScroll, isJust compoundInfo.compoundVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple wItemSize) hasScrolls
	contentRect					= getCompoundContentRect wMetrics visScrolls (PosSizeToRect wItemPos wItemSize)

validateCompoundClipState` :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool !WItemHandle` !*OSToolbox -> (!WItemHandle`,!*OSToolbox)
validateCompoundClipState` wMetrics allClipStates wPtr defId isVisible itemH=:{wItemShow`, wItemPos`,wItemSize`,wItemInfo`,wItems`} tb
	| clipState.clipOk
		| not allClipStates
			= (itemH,tb)
		// otherwise
			# (itemHs,tb)		= validateAllClipStates` wMetrics True wPtr defId itemVisible wItems` tb
			= ({itemH & wItems`=itemHs},tb)
	| otherwise
		# tb					= disposeClipState clipState tb
		# (clipState,itemHs,tb)	= createClipState` wMetrics allClipStates True wPtr contentRect defId itemVisible wItems` tb
		  compoundInfo			= {compoundInfo & compoundLookInfo={compoundLook & compoundClip=clipState}}
		= ({itemH & wItems`=itemHs,wItemInfo`=CompoundInfo` compoundInfo},tb)
where
	itemVisible					= isVisible && wItemShow`
	compoundInfo				= getWItemCompoundInfo` wItemInfo`
	compoundLook				= compoundInfo.compoundLookInfo
	clipState					= compoundLook.compoundClip
	domainRect					= compoundInfo.compoundDomain
	hasScrolls					= (isJust compoundInfo.compoundHScroll, isJust compoundInfo.compoundVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple wItemSize`) hasScrolls
	contentRect					= getCompoundContentRect wMetrics visScrolls (PosSizeToRect wItemPos` wItemSize`)

forceValidCompoundClipState :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool !(WItemHandle .ls .pst) !*OSToolbox -> (!WItemHandle .ls .pst,!*OSToolbox)
forceValidCompoundClipState wMetrics allClipStates wPtr defId isVisible itemH=:{wItemShow,wItemPos,wItemSize,wItemInfo,wItems} tb
	# tb						= disposeClipState clipState tb
	# (clipState,itemHs,tb)		= createClipState wMetrics allClipStates False wPtr contentRect defId itemVisible wItems tb
	  compoundInfo				= {compoundInfo & compoundLookInfo={compoundLook & compoundClip=clipState}}
	= ({itemH & wItemInfo=CompoundInfo compoundInfo,wItems=itemHs},tb)
where
	itemVisible					= isVisible && wItemShow
	compoundInfo				= getWItemCompoundInfo wItemInfo
	compoundLook				= compoundInfo.compoundLookInfo
	clipState					= compoundLook.compoundClip
	domainRect					= compoundInfo.compoundDomain
	hasScrolls					= (isJust compoundInfo.compoundHScroll, isJust compoundInfo.compoundVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple wItemSize) hasScrolls
	contentRect					= getCompoundContentRect wMetrics visScrolls (PosSizeToRect wItemPos wItemSize)

forceValidCompoundClipState` :: !OSWindowMetrics !Bool !OSWindowPtr !(Maybe Id) !Bool !WItemHandle` !*OSToolbox -> (!WItemHandle`,!*OSToolbox)
forceValidCompoundClipState` wMetrics allClipStates wPtr defId isVisible itemH=:{wItemShow`,wItemPos`,wItemSize`,wItemInfo`,wItems`} tb
	# tb						= disposeClipState clipState tb
	# (clipState,itemHs,tb)		= createClipState` wMetrics allClipStates False wPtr contentRect defId itemVisible wItems` tb
	  compoundInfo				= {compoundInfo & compoundLookInfo={compoundLook & compoundClip=clipState}}
	= ({itemH & wItems`=itemHs,wItemInfo`=CompoundInfo` compoundInfo},tb)
where
	itemVisible					= isVisible && wItemShow`
	compoundInfo				= getWItemCompoundInfo` wItemInfo`
	compoundLook				= compoundInfo.compoundLookInfo
	clipState					= compoundLook.compoundClip
	domainRect					= compoundInfo.compoundDomain
	hasScrolls					= (isJust compoundInfo.compoundHScroll, isJust compoundInfo.compoundVScroll)
	visScrolls					= OSscrollbarsAreVisible wMetrics domainRect (toTuple wItemSize`) hasScrolls
	contentRect					= getCompoundContentRect wMetrics visScrolls (PosSizeToRect wItemPos` wItemSize`)

invalidateCompoundClipState :: !(WItemHandle .ls .pst) -> WItemHandle .ls .pst
invalidateCompoundClipState itemH=:{wItemInfo}
	# compoundInfo	= getWItemCompoundInfo wItemInfo
	  compoundLook	= compoundInfo.compoundLookInfo
	  clipState		= compoundLook.compoundClip
	= {itemH & wItemInfo=CompoundInfo {compoundInfo & compoundLookInfo={compoundLook & compoundClip={clipState & clipOk=False}}}}

invalidateCompoundClipState` :: !WItemHandle` -> WItemHandle`
invalidateCompoundClipState` itemH=:{wItemInfo`}
	# compoundInfo	= getWItemCompoundInfo` wItemInfo`
	  compoundLook	= compoundInfo.compoundLookInfo
	  clipState		= compoundLook.compoundClip
	= {itemH & wItemInfo`=CompoundInfo` {compoundInfo & compoundLookInfo={compoundLook & compoundClip={clipState & clipOk=False}}}}
