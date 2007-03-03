module coffeemachine

import StdEnv, StdHtml

//Start world = doHtmlServer (singleUserTask (repeatTaskGC CoffeeMachine )) world
Start world = doHtmlServer (singleUserTask (repeatTaskGC tesy )) world

tesy = STask "OK" 0 <| (\n -> n >= 23,\n -> "Error" +++ toString n) =>> \v -> returnTask v

CoffeeMachine :: Task (String,Int)
CoffeeMachine  
=	 							[Txt "Choose product:",Br,Br] 
								?>>	CTask
								 	[	("Coffee: 100", 	returnV (100,"Coffee"))
									,	("Cappucino: 150",	returnV (150,"Cappucino"))
									,	("Tee: 50",			returnV (50, "Tee"))
									,	("Choclate: 100",	returnV (100,"Choclate"))
									] 
	=>> \(toPay,product)	->	[Txt ("Chosen product: " <+++ product),Br,Br] 
								?>> getCoins (toPay,0)
	=>> \(cancel,returnMoney)->	let nproduct = if cancel "Cancelled" product 
								in
								[Txt ("product = " <+++ nproduct <+++ ", returned money = " <+++ returnMoney),Br,Br] 
								?>>	STask_button "Thanks" (returnV Void)
	#>>							returnV (nproduct,returnMoney) 
where
	getCoins :: (Int,Int) -> Task (Bool,Int)
	getCoins (toPay,paid) = recTask "getCoins" getCoins`
	where
		getCoins` = [Txt ("To pay: " <+++ toPay),Br,Br] 
								?>>	PCTask2	
									( 	CTask [(toString i <+++ " cts", returnV (False,i)) \\ i <- [5,10,20,50,100,200]]
									, 	STask_button "Cancel" (returnV (True,0))
									)
					=>> \(cancel,coin) ->	handleCoin (cancel,coin)

		handleCoin (cancel,coin)
		| cancel			= returnV (cancel,paid)
		| toPay - coin > 0 	= getCoins (toPay - coin,paid + coin)
		= returnV (cancel,coin - toPay)




