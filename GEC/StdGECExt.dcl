definition module StdGECExt

import StdIO
import genericgecs//, StdBimap
	
import StdIO
import genericgecs

// createNGEC is a variant of generic gGEC function, String indicates in which window to put the editor
// String will become name of window; same string = same window  

createNGEC 	   :: String OutputOnly a (Update a (PSt .ps)) *(PSt .ps) -> *((GECVALUE a *(PSt .ps)),*(PSt .ps)) | gGEC{|*|} a & bimap{|*|} ps

// createDummyGEC stores *any* value, no editor is made, no gGEC instance needed
createDummyGEC :: OutputOnly a (Update a (PSt .ps)) *(PSt .ps) -> *((GECVALUE a *(PSt .ps)),*(PSt .ps))
