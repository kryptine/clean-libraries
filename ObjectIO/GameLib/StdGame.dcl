definition module StdGame


//	********************************************************************************
//	Clean Standard Game library, version 1.2
//	
//	StdGame contains the functions one needs during a game.
//	********************************************************************************


import	StdInt, StdString
from	StdIOCommon	import ErrorReport,
							NoError, ErrorViolateDI, ErrorIdsInUse, 
							ErrorUnknownObject, OtherError
from	StdPSt		import PSt, IOSt
import	StdGameDef
from	osgame		import GRESULT


/* predefined bounds */
BND_MAP_CODES       :== 1 << 30
BND_STATIC_BOUNDS   :== 1 << 31

/* skipmove constant */
SK_FOREVER          :==  -1


openGame            :: .gs !(Game .gs) ![GameAttribute .gs] !(PSt .l)
                                            -> (!ErrorReport,!PSt .l)

createGameBitmap    :: !GameBitmap !(GSt .gs) -> (!GRESULT, !GSt .gs)

createAnimation     :: !Sprite     !(GSt .gs) -> (!GRESULT, !GSt .gs)

createNewGameObject :: !ObjectType !SubType !Point2 !(GSt .gs)
                                       -> (!GRESULT, !GSt .gs)

:: ObjectFocus
   = { scrollleft      :: !Int
     , scrollup        :: !Int
     , scrollright     :: !Int
     , scrolldown      :: !Int
     , maxxscrollspeed :: !Int
     , maxyscrollspeed :: !Int
     }

instance zero ObjectFocus

createObjectFocus :: !ObjectFocus !(GSt .gs) -> (!GRESULT, !GSt .gs)

:: EventTarget
   = Self | AllObjects | BoundType Bounds

// modified 01/11/99
createUserGameEvent :: !EventType
                       !EventPar
                       !EventPar
                       !EventTarget
                       !SubType
                       !GameTime
                       !(GSt .gs) -> (!GRESULT, !GSt .gs)

// added 01/11/99
ANY_SUBTYPE :== -1

MAX_VOLUME :==  10000
MIN_VOLUME :==      0

:: Volume
   :== Int

PAN_LEFT   :== -10000
PAN_CENTER :==      0
PAN_RIGHT  :==  10000

:: Pan
   :== Int

DEFAULT_FREQUENCY :== 0

:: Frequency
   :== Int

playSoundSample   :: !SoundID 
                     !Volume
                     !Pan
                     !Frequency
                     !GameTime !(GSt .gs) -> (!GRESULT, !GSt .gs)


getBoundMap       :: !Int !Int !(GSt .gs)
                  -> (!GRESULT, !(!Int, !DirectionSet), !GSt .gs)
setBoundMap       :: !Int !Int  !(!Int, !DirectionSet) !(GSt .gs)
                  -> (!GRESULT, !GSt .gs)


defaultInitObject :: Size state SubType Point2 GameTime 
                                 !*(GSt .gs) -> GameObjectState state *(GSt .gs)
defaultGameObject :: !ObjectType !Size state -> GameObject *(GSt .gs)
defaultObjectRec  :: SubType Point2 Size GameTime 
                                 !*(GSt .gs) -> (!GameObjectRec,!*GSt .gs)

blankScreen       :: Level (GSt .gs)

defaultShadow     :: !Int -> Shadow

defaultMovement       :: Movement
defaultScrollMovement :: !Int -> Movement

alignCentered     :: Alignment
