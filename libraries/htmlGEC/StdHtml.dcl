definition module StdHtml

// main portal for generating Clean Web applications using the iData / GEC technique
// (c) 2005 MJP 

import

// iData modules:

			htmlSettings		// some global settings
		,	htmlFormData		// general iData type definitions
		,	htmlHandler			// the kernel module for iData creation and handling

		,	htmlButtons			// basic collections of buttons, data types for lay-out	control	
		,	htmlDatabase		// collection for storing data, while guarding consistency and versions
		,	htmlExceptions		// collection of global exception handling and storage
		,	htmlFormlib			// collection of advanced iData creating functions  
		,	htmlRefFormlib		// collection of persistent idata maintaining sharing

		,	htmlArrow			// arrow instantiations for iData forms

		,	htmlTask			// for easy creation of workflow tasks based on iData


// html code generation:

	 	,	htmlDataDef			// Clean's ADT representation of Html
		,	htmlStyleDef		// Clean's ADT representation of Style sheets

// free to change when the default style of the generated web pages is not appealing:

		,	htmlStylelib		// style definitions used by iData  

// automatic data base storage and retrieval

		,	Gerda				// Clean's GEneRic Database Access

// of general use:

		,	htmlTrivial			// some trivial generic bimap derives
