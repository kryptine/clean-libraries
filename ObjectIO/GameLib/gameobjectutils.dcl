definition module gameobjectutils

//	Utilities for working with game objects

import	StdOverloaded
import	gameintrface_12
import	gamehandle

// make an 8-bit integer value from eight bools, bit 7..0
CompressBools :: !(!Bool, !Bool, !Bool, !Bool, !Bool, !Bool, !Bool, !Bool) -> Int

// integer value for Bool: only 0 (False) or 1 (True)
toInt01 :: !Bool -> Int

// store an ObjectRec in the game engine
SetObjectRec :: !InstanceID !ObjectType !ObjectRec [SpriteID] !*OSToolbox -> (!GRESULT, !*OSToolbox)

// load an ObjectRec from the game engine
GetObjectRec :: !Int !*OSToolbox -> (!GRESULT, !ObjectType, !ObjectRec, !*OSToolbox)

// get the definition of an object by it's ObjectType
getobject :: ObjectType !(GameHandle gs) -> Maybe (ObjectHandle (GSt gs))

// store the definition of an object in the game definition
putobject :: (ObjectHandle (GSt gs)) !(GameHandle gs) -> GameHandle gs

// find object in tuple list
findinstance :: ![(a,b)] a -> Maybe b  | ==a

// replace object state in tuple list
updateinstance :: a b ![(a,b)] -> [(a,b)]  | ==a

// remove object from tuple list
removeinstance :: a ![(a,b)] -> [(a,b)]  | ==a

// create a DirectionSet from an integer value (0-15)
makeDirectionSet :: !Int -> DirectionSet

toBoundMapCode :: (!Int,!DirectionSet) -> !Int

fromBoundMapCode :: !Int -> (!Int,!DirectionSet)
