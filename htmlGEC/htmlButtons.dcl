definition module htmlButtons

// Prdefined i-Data making html Buttons, forms, and lay-out 

import htmlHandler

derive gForm 	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, Button, CheckBox, RadioButton, PullDownMenu, TextInput
derive gUpd  	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, Button, CheckBox, RadioButton, PullDownMenu, TextInput
derive gPrint 	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, Button, CheckBox, RadioButton, PullDownMenu, TextInput
derive gParse 	(,), (,,), (,,,), (<->), <|>, Date, DisplayMode, Button, CheckBox, RadioButton, PullDownMenu, TextInput

instance toBool   CheckBox, Button, RadioButton		// True if checkbox checked, button pressed
instance toInt    PullDownMenu						// Current index in pull down list
instance toString PullDownMenu						// Corresponding element in pull down list

// lay out

:: <-> a b		= (<->) infixl 5 a b				// place b to the left of a
:: <|> a b		= (<|>) infixl 4 a b				// place b below a

:: DisplayMode a 
				= DisplayMode a						// non-editable display of a
				| EditMode    a						// editable
				| HideMode    a						// hiding a
				| EmptyMode							// nothing to display or hide

// buttons representing classical html buttons

:: Button 		= Pressed 							// button pressed
				| LButton Int String				// label   button, size in pixels, label of button
				| PButton (Int,Int) String			// picture button, (height,width), reference to picture
:: CheckBox		= CBChecked String 					// checkbox 	checked
				| CBNotChecked String				// checkbox 	not checked
:: RadioButton	= RBChecked String					// radiobutton 	checked
				| RBNotChecked String				// radiobutton	not checked
:: PullDownMenu	= PullDown (Int,Int) (Int,[String]) // pulldownmenu (number visible,width) (item chosen,menulist)		
:: TextInput	= TI Int Int						// Input box of size Size for Integers
				| TR Int Real						// Input box of size Size for Reals
				| TS Int String						// Input box of size Size for Strings
	
// special's

:: Date 		= 	Date Int Int Int				// Day Month Year



