definition module id


//	********************************************************************************
//	Clean Standard Object I/O library.
//	********************************************************************************


import	StdOverloaded
import	StdMaybe
from	device		import :: Device
from	systemid	import :: SystemId


::	Id										// General identification
::	RId  mess								// The identification of one-way receivers
::	R2Id mess resp							// The identification of two-way receivers
::	IdTable									// The table of all Id entries
::	IdParent
	=	{	idpIOId		:: !SystemId		// Id of parent process
		,	idpDevice	:: !Device			// Device kind of parent GUI object
		,	idpId		:: !Id				// Id of parent GUI object
		}

windowMenuId			:: Id				// The Id of the WindowMenu
windowMenuRadioId		:: Id				// The Id of the WindowMenu Window list item
windowMenuCascadeId		:: Id				// The Id of the WindowMenu Cascade item
windowMenuTileHId		:: Id				// The Id of the WindowMenu Tile Horizontally item
windowMenuTileVId		:: Id				// The Id of the WindowMenu Tile Vertically   item
windowMenuSeparatorId	:: Id

toId					:: !Int				-> Id
toRId					:: !Int				-> RId  mess
toR2Id					:: !Int				-> R2Id mess resp
sysId					:: !Int				-> Id

fromId					:: !Id				-> Int
isSysId					:: !Id				-> Bool
isCustomId				:: !Id				-> Bool
isCustomRId				:: !Id				-> Bool
isCustomR2Id			:: !Id				-> Bool
isSpecialId				:: !Id				-> Bool

instance ==	Id
instance ==	(RId  mess)
instance == (R2Id mess resp)

rIdtoId					:: !(RId  mess)		-> Id
r2IdtoId				:: !(R2Id mess resp)-> Id

instance toString	Id

//	IdTable operations:

/*	initialIdTable yields an empty IdTable.
*/
initialIdTable			:: *IdTable

/*	memberIdTable checks if the Id argument is a member of the IdTable (True) or not (False).
*/
memberIdTable			:: !Id !*IdTable -> (!Bool,!*IdTable)

/*	okMembersIdTable returns True only iff the list of Ids contains no duplicates and all Ids in 
					 the list do not occur in the IdTable.
*/
okMembersIdTable		:: ![Id] !*IdTable -> (!Bool,!*IdTable)

/*	getIdParent(s) returns the currently bound IdParent associated with the argument Id(s).
	If such a parent was found, Just parent is returned. Otherwise, Nothing is returned.
*/
getIdParent				:: ! Id  !*IdTable -> (! Maybe IdParent, !*IdTable)
getIdParents			:: ![Id] !*IdTable -> (![Maybe IdParent],!*IdTable)

/*	addId(s)ToIdTable adds the argument Id (list) to the IdTable argument.
	The return Bool is True if no duplicate member was found, otherwise it is False.
*/
addIdToIdTable			:: !Id !IdParent    !*IdTable -> *(!Bool,!*IdTable)
addIdsToIdTable			:: ![(Id,IdParent)] !*IdTable -> *(!Bool,!*IdTable)

/*	removeId(s)FromIdTable removes the Id (list) argument from the IdTable argument.
	The Boolean result is True if the Id (list) was actually removed, and it is False otherwise.
	SpecialIds can not be removed (generated by system).
*/
removeIdFromIdTable		:: ! Id  !*IdTable -> (!Bool,!*IdTable)
removeIdsFromIdTable	:: ![Id] !*IdTable -> (!Bool,!*IdTable)
