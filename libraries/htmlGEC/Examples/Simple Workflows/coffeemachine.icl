module coffeemachine

import StdEnv, StdHtml

Start world = doHtmlServer (singleUserTask CoffeeMachineInf2) world

CoffeeMachineInf2 :: *TSt -> (Int,*TSt)
CoffeeMachineInf2 tst
=	(		Coffeemachine2
	#>>		mkTask CoffeeMachineInf2
	) tst

Coffeemachine2 tst
=	( 							[Txt "Choose product:", Br] 
								?>>	CTask_button
								 	[	("Coffee: 100", 	returnV (100,"Coffee"))
									,	("Cappucino: 150",	returnV (150,"Cappucino"))
									,	("Tee: 50",			returnV (50, "Tee"))
									,	("Choclate: 100",	returnV (100,"Choclate"))
									] 
	=>> \(toPay,product)	->	[Txt ("Chosen product: " <+++ product), Br] 
								?>> getCoins (toPay,0)
	=>> \(cancel,returnMoney)->	let nproduct = if cancel "Cancelled" product in
								[Txt ("product = " <+++ product <+++  ", returned money = " <+++ returnMoney), Br] 
								?>>	STask_button "Thanks" (returnV Void)
	#>>							returnV (nproduct,returnMoney) 
	) tst
where
	getCoins (toPay,paid) tst
	= 	(							[Txt ("To pay: " <+++ toPay), Br] 
									?>>	PCTask2	
										( 	CTask_button [(toString i <+++ " cts", returnV (False,i)) \\ i <- [5,10,20,50,100,200]]
										, 	STask_button "Cancel" (returnV (True,0))
										)
		=>> \(cancel,coin) ->		if cancel (returnV (cancel,paid))
										(if (toPay - coin > 0) (mkTask (getCoins (toPay - coin,paid + coin)))
											(returnV (cancel,coin - toPay))
										)
		) tst

CoffeeMachineInf :: *TSt -> (Int,*TSt)
CoffeeMachineInf tst
# (_,tst) = Coffeemachine tst
= mkTask CoffeeMachineInf tst

Coffeemachine tst
# ((toPay,product),tst) 		= (	[Txt "Choose product:", Br] ?>>
								  	CTask_button
										 	[	("Coffee: 100", 	returnV (100,"Coffee"))
											,	("Cappucino: 150",	returnV (150,"Cappucino"))
											,	("Tee: 50",			returnV (50, "Tee"))
											,	("Choclate: 100",	returnV (100,"Choclate"))
											] 
									)tst
# ((cancel,returnMoney),tst) 	= ( [Txt ("Chosen product: " <+++ product), Br] ?>> 
									getCoins (toPay,0)
								  ) tst
# product 						= if cancel "Cancelled" product
# (_,tst)						= ( [Txt ("product = " <+++ product <+++  ", returned money = " <+++ returnMoney), Br] ?>>
									STask_button "Thanks" (returnV Void)
								  ) tst
= returnV (product,returnMoney) tst
where
	getCoins (toPay,paid) tst
	# ((cancel,coin),tst)= (	[Txt ("To pay: " <+++ toPay), Br] ?>>
								PCTask2	( CTask_button [(toString i <+++ " cts", returnV (False,i)) \\ i <- [5,10,20,50,100,200]]
										, STask_button "Cancel" (returnV (True,0))
										)
							) tst
	| cancel			= returnV (cancel,paid) tst
	| toPay - coin > 0 	= mkTask (getCoins (toPay - coin,paid + coin)) tst
	= returnV (cancel,coin - toPay) tst






