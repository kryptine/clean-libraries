module Worms

/*
    Worms Demonstration Game for the Clean Game Library
    
    Version:  2.0
    Author:   Mike Wiering (mike.wiering@cs.kun.nl)
*/

import StdEnv, StdIO
import StdGameDef, StdGame, StdGSt, GameFunctions
import L1, L2, L3, WORM, HEAD
import Random

::  GameState
    = { curlevel    :: !Int
      , maxlevel    :: !Int
      , quit        :: !Bool
      , wormlist    :: ![RealXY]
      , gameover    :: !Bool
      , timecounter :: !Int
      , randseed    :: !RandomSeed
      }

initialGameState = { curlevel = 0
                   , maxlevel = 7
                   , quit = False
                   , wormlist = []
                   , gameover = False
                   , timecounter = 0
                   , randseed = nullRandomSeed
                   }

/* move with speed V */
V = 3.0  /* 24 rem V must be 0 */

/* ---------- main program: load game definition and start the game! ---------- */

Start :: *World -> *World
Start world 
    # (seed, world) = getNewRandomSeed world
    = startGame WormsDemo {initialGameState & randseed = seed}
              [ScreenSize {w = 640, h = 480}, ColorDepth 16] world 


/* ---------- the complete game definition ---------- */

WormsDemo :: (Game GameState)
WormsDemo =
    { levels = [ blankScreen
               , GameLevel1
               , blankScreen
               , GameLevel2
               , blankScreen
               , GameLevel3
               , blankScreen
               ]
    , quitlevel = accGSt WormsQuitFunction
    , nextlevel = accGSt WormsNextLevelFunction
    , textitems = accGSt WormsTextItems
    }


/* if the quit function returns true, the game engine quit the level */

WormsQuitFunction :: GameState -> (Bool, GameState)
WormsQuitFunction gst
    = (gst.quit, gst)


/* function that returns the next level to run, 0 = end game */

WormsNextLevelFunction :: GameState -> (Int, GameState)
WormsNextLevelFunction gst =: {curlevel, maxlevel, gameover}
    = (nextLevel, {gst & curlevel = nextLevel
                       , quit = False
                       , timecounter = (time nextLevel)
                       })
where
    nextLevel = if (gameover || (curlevel + 1 > maxlevel)) 0 (curlevel + 1)
    time l = if (l == maxlevel) 500 (if (l rem 2 == 1) 100 (~1))

/* function that returns text to be displayed */

WormsTextItems :: GameState -> ([GameText], GameState)
WormsTextItems gst =: {curlevel, gameover, timecounter, maxlevel}
    #   gst = {gst & timecounter = timecounter - 1}
    |   gst.timecounter == 0
        = ([], {gst & quit = True})
    |   gameover
        |   timecounter < 0
            =   ([GameOver], {gst & timecounter = 250})
        =   ([GameOver], gst)
    =   if (curlevel == maxlevel)
            ([Ending1 timecounter, Ending2 timecounter], gst)
            (if (curlevel rem 2 == 1)
                ([LevelStat ((curlevel + 1) / 2)], gst)
                ([], gst)
            )

/* ---------- definitions of the levels ---------- */

/* block size */
W :== 24
H :== 24

DEFAULT_SIZE :== {w = W, h = H}

/* object codes (corresponds with level map) */

OBJ_START       :== 0x10

OBJ_WORMHEAD    :== 0x10
OBJ_WORMSEGMENT :== 0x11
OBJ_FOOD        :== 0x12

OBJ_WALL        :== 0x80

/* user events */
EV_STOP         :== 0
EV_DIE          :== 1
EV_GAMEOVER     :== 2


/* ---------- level 1 ---------- */

GameLevel1
  = { boundmap     = { map = Level1Bounds
                     , blocksize = DEFAULT_SIZE
                     , objstart  = OBJ_START
                     , startobjx = 0
                     , startobjy = 0
                     }
    , initpos      = {x = W - 8, y = 0}
    , layers       = [Level1Layer]
    , objects      = ObjectList
    , music        = Nothing // Just BackGroundMusic
    , soundsamples = []
    , leveloptions = { fillbackground = Nothing
                     , escquit        = False
                     , debugscroll    = False
                     , fadein         = False
                     , fadeout        = False
                     }
    }

Level1Layer =
    { bmp       = Level1Bitmap
    , layermap  = Level1Map
    , sequences = []
    , movement  = defaultMovement
    }


/* ---------- level 2 ---------- */

GameLevel2
  = { boundmap     = { map = Level2Bounds
                     , blocksize = DEFAULT_SIZE
                     , objstart  = OBJ_START
                     , startobjx = 0
                     , startobjy = 0
                     }
    , initpos      = {x = W - 8, y = 0}
    , layers       = [Level2Layer]
    , objects      = ObjectList
    , music        = Nothing // Just BackGroundMusic
    , soundsamples = []
    , leveloptions = { fillbackground = Nothing
                     , escquit        = False
                     , debugscroll    = False
                     , fadein         = False
                     , fadeout        = False
                     }
    }

Level2Layer =
    { bmp       = Level2Bitmap
    , layermap  = Level2Map
    , sequences = []
    , movement  = defaultMovement
    }


/* ---------- level 3 ---------- */

GameLevel3
  = { boundmap     = { map = Level3Bounds
                     , blocksize = DEFAULT_SIZE
                     , objstart  = OBJ_START
                     , startobjx = 0
                     , startobjy = 0
                     }
    , initpos      = {x = W - 8, y = 0}
    , layers       = [Level3Layer]
    , objects      = ObjectList
    , music        = Nothing       // Just BackGroundMusic
    , soundsamples = []
    , leveloptions = { fillbackground = Nothing
                     , escquit        = False
                     , debugscroll    = False
                     , fadein         = False
                     , fadeout        = False
                     }
    }

Level3Layer =
    { bmp       = Level3Bitmap
    , layermap  = Level3Map
    , sequences = []
    , movement  = defaultMovement
    }



/* ---------- worm object ---------- */

/* worm head sprites */
SPR_WH_UP    :== 1
SPR_WH_LEFT  :== 2
SPR_WH_DOWN  :== 3
SPR_WH_RIGHT :== 4

ObjectList = [WormHead, WormSegment, Food, Wall]

/* bounds */
BND_WORMHEAD     :==   0x0001
BND_WORMSEGMENT  :==   0x0002
BND_FOOD         :==   0x0004
BND_WALL         :==   0x0008

/*
    the wormstate contains the next x/y direction to move, the position where
    new segments can be added, and the sprites for all directions
*/

:: WormState
   = { xv        :: !Real        /* next x-speed */
     , yv        :: !Real        /* next y-speed */
     , count     :: !Int         /* current length of the worm */
     , add       :: !Int         /* number of segments to add when worm eats food */
     , more      :: !Int         /* number of segments that still have to be added */
     , lastpoint :: !RealXY      /* position of last segment */
     , next      :: !Int         /* next sprite */
     }


/* layer height, to display some objects in front of others */
NormalLayer = 1
TopLayer    = 2

WormHead
    #   obj = defaultGameObject OBJ_WORMHEAD sz wormstate
    #   obj = { obj
              & sprites    = WormHeadSpriteList
              , init       = (newInit sz wormstate)
              , keydown    = newKeyDown
              , move       = newMove
              , collide    = newCollide
              , userevent  = newUserEvent
              , touchbound = newTouchBound
              }
    =   obj
where
    sz = DEFAULT_SIZE

    wormstate = { xv        = V
                , yv        = 0.0
                , count     = 3
                , add       = 1
                , more      = 0
                , lastpoint = {rx = 0.0, ry = 0.0}
                , next      = 0
                }

    newInit size state subcode pos time gs
        # (objrec, gs) =  defaultObjectRec subcode pos size time gs
        # (_, gs)      =  createObjectFocus zero gs
        # state        =  { state & next = SPR_WH_RIGHT }
        # gs           =  setwormlist [defSpeed, defSpeed, defSpeed] gs
        # (_, gs)      =  createNewGameObject OBJ_WORMSEGMENT 1
                             {objrec.pos & x = objrec.pos.x - 1 * W} gs
        # (_, gs)      =  createNewGameObject OBJ_WORMSEGMENT 2
                             {objrec.pos & x = objrec.pos.x - 2 * W} gs
        # lastx        =  objrec.pos.x - 3 * W
          lasty        =  objrec.pos.y
        # state        =  {state & lastpoint = {state.lastpoint & rx = toReal lastx,
                                                   ry = toReal lasty}, more = 0}
        # (_, gs)      =  createNewGameObject OBJ_FOOD 0
                             {x = 0, y = 0} gs
        # objrec       =  { objrec
                          & ownbounds     = BND_WORMHEAD
                          , collidebounds = BND_WORMSEGMENT + BND_FOOD +
                                               BND_STATIC_BOUNDS
                          , offset        = {x = ~2, y = ~2}
                          , size          = {w = W, h = H}
                          , options       = {objrec.options & checkkeyboard = True}
                          , skipmove      = 0
                          , layer         = AtLayer TopLayer
                          , currentsprite = SPR_WH_RIGHT
                          }
        = {st=state, or=objrec, gs=gs}

    newKeyDown GK_LEFT objst=:{st}
        = {objst & st = {st & xv = (~V), yv = 0.0, next = SPR_WH_LEFT}}
    newKeyDown GK_RIGHT objst=:{st}
        = {objst & st = {st & xv = V, yv = 0.0, next = SPR_WH_RIGHT}}
    newKeyDown GK_UP objst=:{st}
        = {objst & st = {st & xv = 0.0, yv = (~V), next = SPR_WH_UP}}
    newKeyDown GK_DOWN objst=:{st}
        = {objst & st = {st & xv = 0.0, yv = V, next = SPR_WH_DOWN}}
    newKeyDown GK_ESCAPE objst
        = newTouchBound 0 0 objst
    newKeyDown _ objst
        = objst

    newMove objst=:{st, or, gs}
        #   nextspeed = {rx = st.xv, ry = st.yv}
        #   (wormlist, gs) = getwormlist gs
        #   gs = setwormlist (take st.count [nextspeed:wormlist]) gs
        #   or = {or & speed = nextspeed
                     , currentsprite = st.next
                     , skipmove = (24 / (toInt V)) -1
                     }
        |   st.more == 0
            # last = wormlist!!((length wormlist) - 1)
            # newx = last.rx * (24.0 / V) + st.lastpoint.rx
              newy = last.ry * (24.0 / V) + st.lastpoint.ry
            # st = {st & lastpoint = {rx = newx, ry = newy}}
            = {st=st, or=or, gs=gs}
        #   (_, gs) = createNewGameObject OBJ_WORMSEGMENT
                        (st.count - st.more)
                        {x = toInt st.lastpoint.rx, y = toInt st.lastpoint.ry} gs
        #   st = {st & more = st.more - 1}
        = {st=st, or=or, gs=gs}

    newCollide bounds othertype _ objst=:{st, or, gs}
        |   othertype == OBJ_FOOD
            #   st = {st & count = st.count + st.add
                         , more = st.more + st.add
                         , add = st.add + 1
                         }
            |   st.add == 10
                = quitlevel {st=st, or=or, gs=gs}
            = {st=st, or=or, gs=gs}
        |   othertype == OBJ_WORMSEGMENT
            # or = {or & ownbounds = 0, collidebounds = 0}
            = newTouchBound bounds 0 {st=st, or=or, gs=gs}
        = {st=st, or=or, gs=gs}

    newTouchBound _ _ objst=:{st, or, gs}
        # gs = setgameover True gs
        # (_,gs) = createUserGameEvent EV_STOP     0 0 AllObjects ANY_SUBTYPE   0 gs
        # (_,gs) = createUserGameEvent EV_GAMEOVER 0 0 Self       ANY_SUBTYPE 350 gs
        = {st=st, or=or, gs=gs}

    defSpeed = {rx = V, ry = 0.0}

    newUserEvent ev par1 par2 objst=:{st, or, gs}
        | ev == EV_STOP
            # (rnd, gs) = Rnd gs
            # (_, gs)   = createUserGameEvent EV_DIE 0 0 Self ANY_SUBTYPE (rnd rem 150) gs
            = {st=st, or={or & speed = {rx = 0.0, ry = 0.0}
                             , skipmove = ~1
                             , options = {or.options & checkkeyboard = False}
                             }, gs=gs}
        | ev == EV_DIE
            = {st=st, or = {or & currentsprite = SPR_INVISIBLE}, gs=gs}
        | ev == EV_GAMEOVER
            = {st=st, or=or, gs=gs}
        = {st=st, or=or, gs=gs}


WormSegment
    #   obj = defaultGameObject OBJ_WORMSEGMENT sz Void
    #   obj = { obj
              & sprites    = [WormSegmentSprite]
              , init       = (newInit sz Void)
              , move       = newMove
              , userevent  = newUserEvent
              }
    = obj
where
    sz = DEFAULT_SIZE

    newInit size state subtype pos time gs
        # (objrec, gs)  =   defaultObjectRec subtype pos size time gs
        # objrec        =   { objrec
                            & ownbounds     = if (subtype > 1) BND_WORMSEGMENT 0
                            , collidebounds = 0
                            , skipmove      = 0     // toInt (2.0 / V) -1
                            , layer         = AtLayer NormalLayer
                            }
        = {st=state, or=objrec, gs=gs}

    newMove objst=:{st, or, gs}
        #   (wormlist, gs)  = getwormlist gs
        #   or = { or & skipmove = (24 / (toInt V)) -1 }
        |   or.subcode + 1 > length wormlist
            = {st=st, or=or, gs=gs}
        #   or = {or & speed = wormlist!!(or.subcode)}
        = {st=st, or=or, gs=gs}

    newUserEvent ev par1 par2 objst=:{st, or, gs}
        | ev == EV_STOP
            # (rnd, gs) = Rnd gs
            # (_,gs)    = createUserGameEvent EV_DIE 0 0 Self ANY_SUBTYPE (rnd rem 150) gs
            # or        = {or & speed = {rx = 0.0, ry = 0.0}
                              , skipmove = ~1
                              , options = {or.options & checkkeyboard = False}}
            = {st=st, or=or, gs=gs}
        | ev == EV_DIE
            # or = {or & currentsprite = SPR_INVISIBLE}
            = {st=st, or=or, gs=gs}
        = {st=st, or=or, gs=gs}


/* ---------- wall object ---------- */


Wall 
    #   obj = defaultGameObject OBJ_WALL sz Void
    #   obj = {obj & init = (newInit sz Void)}
    = obj
where
    sz = DEFAULT_SIZE
    newInit size state subcode pos time gs
        # (objrec, gs)  =   defaultObjectRec subcode pos size time gs
        # objrec        =   { objrec & ownbounds = BND_WALL }
        = {st=state, or=objrec, gs=gs}



/* ---------- food object ---------- */

SPR_INVISIBLE  = 0
SPR_VISIBLE    = 1

Food
    #   obj = defaultGameObject OBJ_FOOD sz Void
    #   obj = { obj
              & sprites    = [WormFoodSprite]
              , init       = (newInit sz Void)
              , move       = newMove
              , touchbound = newTouchBound
              , collide    = newCollide
              , userevent  = newUserEvent
              }
    = obj
where
    sz = DEFAULT_SIZE

    newInit size state subtype pos time gs
        # (objrec, gs)  =   defaultObjectRec subtype pos size time gs
        # (p, gs)       =   newPos gs
        # objrec        =   { objrec
                            & ownbounds      = 0
                            , collidebounds  = BND_WORMHEAD + BND_WORMSEGMENT +
                                                 BND_WALL
                            , skipmove       = 50
                            , layer          = AtLayer NormalLayer
                            , pos            = p
                            , currentsprite  = SPR_INVISIBLE
                            }
        = {st=state, or=objrec, gs=gs}

    newPos gs 
        # (rnd1, gs) = Rnd gs
        # (rnd2, gs) = Rnd gs
        = ( { x = W * (2 + (rnd1 rem 24))
            , y = H * (1 + (rnd2 rem 18))}, gs)

    newCollide bnd ot _ objst
        = newTouchBound bnd 0 objst

    newTouchBound bnd mapcode objst=:{st, or, gs}
        #   (p, gs) = newPos gs
        #   or = {or & pos = p
                     , ownbounds = 0
                     , skipmove = 50
                     , currentsprite = SPR_INVISIBLE
                     }
        = {st=st, or=or, gs=gs}

    newMove objst=:{or}
        #   or = {or & currentsprite = SPR_VISIBLE
                     , ownbounds = BND_FOOD
                     , skipmove = ~1
                     }
        = {objst & or = or}

    newUserEvent ev par1 par2 objst=:{st, or, gs}
        | ev == EV_STOP
            # (rnd, gs) = Rnd gs
            # (_,gs)    = createUserGameEvent EV_DIE 0 0 Self ANY_SUBTYPE (rnd rem 150) gs
            # or        = {or & speed = {rx = 0.0, ry = 0.0}
                              , skipmove = ~1
                              , options = {or.options & checkkeyboard = False}}
            = {st=st, or=or, gs=gs}
        | ev == EV_DIE
            # or = {or & currentsprite = SPR_INVISIBLE}
            = {st=st, or=or, gs=gs}
        = {st=st, or=or, gs=gs}

/* ---------- useful functions for objects ---------- */

/* quit the level */

quitlevel objst=:{st, or, gs}
    #   gs = appGSt setQuit gs
    =   {st=st, or=or, gs=gs}
where
    setQuit :: GameState -> GameState
    setQuit gst = {gst & quit = True}

/* wormlist functions */
setwormlist l gs = appGSt (setgstwormlist l) gs
setgstwormlist :: [RealXY] GameState -> GameState
setgstwormlist l gst = {gst & wormlist = l}

getwormlist gs = accGSt getgstwormlist gs
getgstwormlist :: GameState -> ([RealXY], GameState)
getgstwormlist gst = (gst.wormlist, gst)

/* gameover functions */
setgameover b gs = appGSt (setgstgameover b) gs
setgstgameover :: Bool GameState -> GameState
setgstgameover b gst = {gst & gameover = b}

getgameover gs = accGSt getgstgameover gs
getgstgameover :: GameState -> (Bool, GameState)
getgstgameover gst = (gst.gameover, gst)



/* ---------- music ---------- */

BackGroundMusic
  = { musicfile = "Helio.mid"
    , restart   = True
    , continue  = False
    }


/* ---------- bitmaps and sprites ---------- */

WormHeadSpriteList = [ws SPR_WH_UP, ws SPR_WH_LEFT, ws SPR_WH_DOWN, ws SPR_WH_RIGHT]
where
    ws :: Int -> Sprite
    ws n = { bitmap = HeadBitmap, sequence = [(n, 100)], loop = True }

WormSegmentSprite =
    { bitmap    = WormBitmap
    , sequence  = [(3,100)]
    , loop      = True
    }

WormFoodSprite =
    { bitmap    = WormBitmap
    , sequence  = [(1,35),(2,35)]
    , loop      = True
    }


/* ---------- statistics ---------- */

BigStyle =
    { fontname = "Arial"
    , fontsize = 48
    , bold     = True
    , italic   = False
    }

GameOver =
    { format    = "GAME OVER"
    , value     = Nothing
    , position  = {x = 0, y = 0}
    , style     = BigStyle
    , color     = White
    , shadow    = Just (MakeShadow 3 Grey)
    , alignment = alignCentered
    }

LevelStat n =
    { format    = "LEVEL %d"
    , value     = Just n
    , position  = {x = 0, y = 0}
    , style     = {BigStyle & fontsize = 32}
    , color     = White
    , shadow    = Just (MakeShadow 2 Grey)
    , alignment = alignCentered
    }

MakeShadow offset color =
    { shadowpos   = {x = offset, y = offset}
    , shadowcolor = color
    }

Ending1 n
  # n = n * 2
  = { format    = "CONGRATULATIONS!!!"
    , value     = Nothing
    , position  = {x = 0, y = ~30}
    , style     = {BigStyle & fontsize = 34}
    , color     = RGB { r = 240 + (n rem 32)
                      , g = 224 + (n rem 32) * 2
                      , b = 196 + (n rem 32) * 3}
    , shadow    = Just (MakeShadow 2 Grey)
    , alignment = alignCentered
    }

Ending2 n
  = { format    = "You have completed all levels!"
    , value     = Nothing
    , position  = {x = 0, y = 30}
    , style     = {BigStyle & fontsize = 28, italic = True}
    , color     = RGB { r = 224 + (n rem 32)
                      , g = 224 + (n rem 32)
                      , b = 224 + (n rem 32) * 2}
    , shadow    = Just (MakeShadow 2 Grey)
    , alignment = alignCentered
    }

Rnd gs = accGSt gsrand gs
gsrand gs=:{randseed}
    # (x, newseed) = random randseed
    = (x, {gs & randseed = newseed})


