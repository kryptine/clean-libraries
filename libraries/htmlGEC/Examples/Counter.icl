module Counter

import StdEnv
import StdHtml

Start world  = doHtml MyPage world

MyPage hst
# ((_,counterGEC),hst) = counterHGEC "counter" HEdit 0 hst
= (Head 
	[ Hd_Title "Counter Example"
	] 
	[ H1 "Counter Example"
	, Br  
	, counterGEC
	],hst)



