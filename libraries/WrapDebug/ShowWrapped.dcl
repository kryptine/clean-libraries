/*
	Show Wrapped Node

	Version 1.0.4
	Ronny Wichers Schreur
	ronny@cs.kun.nl
*/
definition module ShowWrapped

from Wrap import ::DeeplyWrappedNode, ::WrappedNode, ::WrappedArg, class wrap

:: ShowWrappedOptions
	=	Don`tShowParentheses | ShowParentheses
	// in list implies don't parenthesise
	|	ShowInList | ShowInUnboxedList | ShowInUnboxedRecordList

class showWrapped a :: !ShowWrappedOptions !a -> [{#Char}]

instance showWrapped (WrappedNode arg) | showWrapped arg
instance showWrapped WrappedArg

showWrappedNode :: a -> [{#Char}] | showWrapped a
showApplication :: ShowWrappedOptions {#Char} {!arg} -> [{#Char}]
															| showWrapped arg
class prune a | wrap a where
	prune :: !Int !Int !Int a -> a

instance prune (WrappedNode a) | prune a
instance prune WrappedArg
chop :: !Int [{#Char}] -> [{#Char}]
