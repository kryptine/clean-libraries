definition module calcAGEC

import StdClass
import StdAGEC, buttonGEC

calcGEC 	:: a [[(Button,a->a)]] 	-> AGEC a | gGEC {|*|} a // apply pressed function to argument
intcalcGEC 	:: Int 					-> AGEC Int
realcalcGEC :: Real 				-> AGEC Real
