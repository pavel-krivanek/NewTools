Class {
	#name : 'StDebuggerExtensionMechanismTest',
	#superclass : 'TestCase',
	#instVars : [
		'debugger',
		'oldActivatedExtensions'
	],
	#category : 'NewTools-Debugger-Tests-Presenters',
	#package : 'NewTools-Debugger-Tests',
	#tag : 'Presenters'
}

{ #category : 'accessing' }
StDebuggerExtensionMechanismTest >> debugger [
	^ debugger ifNil: [ debugger := self debuggerClass basicNew ]
]

{ #category : 'accessing' }
StDebuggerExtensionMechanismTest >> debuggerClass [
	^ StDebugger
]

{ #category : 'helpers' }
StDebuggerExtensionMechanismTest >> disableTStDebuggerExtensionTestClassAsExtension [

	TStDebuggerExtensionTestClass class compile: 'isOnlyForTests

	^ true'
]

{ #category : 'helpers' }
StDebuggerExtensionMechanismTest >> enableTStDebuggerExtensionTestClassAsExtension [

	TStDebuggerExtensionTestClass class compile: 'isOnlyForTests

	^ false'
]

{ #category : 'helpers' }
StDebuggerExtensionMechanismTest >> hideTStDebuggerExtensionTestClass [

	TStDebuggerExtensionTestClass showInDebugger: false
]

{ #category : 'helpers' }
StDebuggerExtensionMechanismTest >> makeTStDebuggerExtensionTestClassAcceptPredicate [

	TStDebuggerExtensionTestClass class compile:
		'acceptsPredicate: aStDebuggerContextPredicate

	^ true'
]

{ #category : 'helpers' }
StDebuggerExtensionMechanismTest >> makeTStDebuggerExtensionTestClassDenyPredicate [

	TStDebuggerExtensionTestClass class compile:
		'acceptsPredicate: aStDebuggerContextPredicate

	^ false'
]

{ #category : 'running' }
StDebuggerExtensionMechanismTest >> setUp [

	super setUp.
	oldActivatedExtensions := self debuggerClass activatedDebuggerExtensions.
	StDummyDebuggerPresenter showInDebugger: false
]

{ #category : 'helpers' }
StDebuggerExtensionMechanismTest >> showTStDebuggerExtensionTestClass [

	TStDebuggerExtensionTestClass showInDebugger: true
]

{ #category : 'running' }
StDebuggerExtensionMechanismTest >> tearDown [

	| allDebuggerExtensions |
	allDebuggerExtensions := StDebugger extensionToolsClasses.
	allDebuggerExtensions do: [ :extension |
		| wasActivated |
		wasActivated := oldActivatedExtensions includes: extension.
		extension showInDebugger = wasActivated ifFalse: [
			extension showInDebugger: wasActivated ] ].
	TStDebuggerExtensionTestClass showInDebugger: false.
	StDummyDebuggerPresenter showInDebugger: false.
	self disableTStDebuggerExtensionTestClassAsExtension.
	self makeTStDebuggerExtensionTestClassAcceptPredicate.
	self hideTStDebuggerExtensionTestClass.
	super tearDown
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testAcceptsPredicate [

	"By default, a debugger extension accepts any context predicate, even `nil`"
	self assert: (TStDebuggerExtension acceptsPredicate: nil)
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testDynamicLayoutWithAndWithoutExtension [

	| dbg toolPage session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self denyCollection: dbg stackAndCodeContainer children includesAny: {#extensionToolsNotebook }.

	"We activate an extension"
	StDummyDebuggerPresenter showInDebugger: true.
	self assert: dbg extensionToolNotebook pages size equals: 1.
	self assert: dbg extensionTools size equals: 1.
	self assertCollection: dbg stackAndCodeContainer children includesAny: {#extensionToolsNotebook }.
	toolPage := dbg extensionToolNotebook pages first.
	self assert: toolPage class identicalTo: SpNotebookPage.
	self
		assert: toolPage presenterProvider value class
		identicalTo: StDummyDebuggerPresenter.
	self
		assert: toolPage title
		equals: StDummyDebuggerPresenter new debuggerExtensionToolName.
	self
		assert: toolPage presenterProvider value debugger
		identicalTo: dbg.
	self
		assertCollection: dbg extensionTools
		includesAll: { toolPage presenterProvider value }.

	"We remove the extension"
	StDummyDebuggerPresenter showInDebugger: false.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self denyCollection: dbg stackAndCodeContainer children includesAny: {#extensionToolsNotebook }
]

{ #category : 'tests - extensions' }
StDebuggerExtensionMechanismTest >> testExtensionToolsClasses [

	| extensionClasses |
	extensionClasses := StDebugger extensionToolsClasses.
	self deny: (extensionClasses includesAny:
			 (TStDebuggerExtension users select: [ :c | c isOnlyForTests ]))
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplay [

	| dbg session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.

	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self
		denyCollection: dbg extensionsToDisplay
		includesAny: (TStDebuggerExtension users select: [ :extension |
				 extension isOnlyForTests ]).
	self
		denyCollection: dbg extensionsToDisplay
		includesAny: (TStDebuggerExtension users reject: [ :extension |
				 extension acceptsPredicate: dbg contextPredicate ])
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionAcceptsPredicateAndIsNowActivated [

	| dbg toolPage session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self makeTStDebuggerExtensionTestClassAcceptPredicate.
	self hideTStDebuggerExtensionTestClass.

	self deny: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self assert:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.

	"We display the extension"
	self showTStDebuggerExtensionTestClass.
	
	self assert: TStDebuggerExtensionTestClass showInDebugger.

	"The extension is now activated and as it accepts the context predicate, it is displayed"
	self
		assertCollection: dbg extensionsToDisplay asOrderedCollection
		equals: { TStDebuggerExtensionTestClass } asOrderedCollection.

	self assert: dbg extensionToolNotebook pages size equals: 1.
	self assert: dbg extensionTools size equals: 1.
	self
		assertCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.
	toolPage := dbg extensionToolNotebook pages first.
	self assert: toolPage class identicalTo: SpNotebookPage.
	self
		assert: toolPage presenterProvider value class
		identicalTo: TStDebuggerExtensionTestClass.
	self
		assert: toolPage title
		equals: TStDebuggerExtensionTestClass new debuggerExtensionToolName.
	self
		assert: toolPage presenterProvider value debugger
		identicalTo: dbg.
	self
		assertCollection: dbg extensionTools
		equals: { toolPage presenterProvider value } asOrderedCollection
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionAcceptsPredicateAndIsNowDeactivated [

	| dbg toolPage session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self makeTStDebuggerExtensionTestClassAcceptPredicate.
	self showTStDebuggerExtensionTestClass.

	self assert: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self assert:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	"The extension is displayed"
	self
		assertCollection: dbg extensionsToDisplay asOrderedCollection
		equals: { TStDebuggerExtensionTestClass } asOrderedCollection.

	self assert: dbg extensionToolNotebook pages size equals: 1.
	self assert: dbg extensionTools size equals: 1.
	self
		assertCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.
	toolPage := dbg extensionToolNotebook pages first.
	self assert: toolPage class identicalTo: SpNotebookPage.
	self
		assert: toolPage presenterProvider value class
		identicalTo: TStDebuggerExtensionTestClass.
	self
		assert: toolPage title
		equals: TStDebuggerExtensionTestClass new debuggerExtensionToolName.
	self
		assert: toolPage presenterProvider value debugger
		identicalTo: dbg.
	self
		assertCollection: dbg extensionTools
		equals: { toolPage presenterProvider value } asOrderedCollection.

	"We hide the extension"
	self hideTStDebuggerExtensionTestClass.
	
	self deny: TStDebuggerExtensionTestClass showInDebugger.

	"The extension is deactivated, it is thus hidden even though it accepts the context predicate."
	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionDeniesPredicateAndIsNowActivated [

	| dbg session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self makeTStDebuggerExtensionTestClassDenyPredicate.
	self hideTStDebuggerExtensionTestClass.

	self deny: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self deny:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.

	"We display the extension"
	self showTStDebuggerExtensionTestClass.

	self assert: TStDebuggerExtensionTestClass showInDebugger.

	"The extension is now activated but as it does not accept the context predicate, it is not displayed"
	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionIsActivatedAndNowAcceptsPredicate [

	| dbg toolPage session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self makeTStDebuggerExtensionTestClassDenyPredicate.
	self showTStDebuggerExtensionTestClass.

	self assert: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self deny:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.

	"We accept the context predicate"
	self makeTStDebuggerExtensionTestClassAcceptPredicate.

	"The extension is activated and now accepts the predicate so it should be displayed in the debugger"
	self
		assertCollection: dbg extensionsToDisplay asOrderedCollection
		equals: { TStDebuggerExtensionTestClass } asOrderedCollection.

	dbg updateExtensionsFromSession: session.
	self assert: dbg extensionToolNotebook pages size equals: 1.
	self assert: dbg extensionTools size equals: 1.
	self
		assertCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.
	toolPage := dbg extensionToolNotebook pages first.
	self assert: toolPage class identicalTo: SpNotebookPage.
	self
		assert: toolPage presenterProvider value class
		identicalTo: TStDebuggerExtensionTestClass.
	self
		assert: toolPage title
		equals: TStDebuggerExtensionTestClass new debuggerExtensionToolName.
	self
		assert: toolPage presenterProvider value debugger
		identicalTo: dbg.
	self
		assertCollection: dbg extensionTools
		equals: { toolPage presenterProvider value } asOrderedCollection
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionIsActivatedAndNowAcceptsPredicateWithTwoConsecutiveUpdates [

	| dbg toolPage session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self makeTStDebuggerExtensionTestClassDenyPredicate.
	self showTStDebuggerExtensionTestClass.

	self assert: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self deny:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.

	"We accept the context predicate"
	self makeTStDebuggerExtensionTestClassAcceptPredicate.

	"The extension is activated and now accepts the predicate so it should be displayed in the debugger"
	self
		assertCollection: dbg extensionsToDisplay asOrderedCollection
		equals: { TStDebuggerExtensionTestClass } asOrderedCollection.

	dbg updateExtensionsFromSession: session.
	self assert: dbg extensionToolNotebook pages size equals: 1.
	self assert: dbg extensionTools size equals: 1.
	self
		assertCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.
	toolPage := dbg extensionToolNotebook pages first.

	"A second update does not create a second page for the extension"
	dbg updateExtensionsFromSession: session.
	self assert: dbg extensionToolNotebook pages size equals: 1.
	self
		assert: dbg extensionToolNotebook pages first
		identicalTo: toolPage.
	self assert: dbg extensionTools size equals: 1
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionIsActivatedAndNowDeniesPredicate [

	| dbg toolPage session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self showTStDebuggerExtensionTestClass.
	self makeTStDebuggerExtensionTestClassAcceptPredicate.

	self assert: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self assert:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	"The extension is displayed"
	self
		assertCollection: dbg extensionsToDisplay asOrderedCollection
		equals: { TStDebuggerExtensionTestClass } asOrderedCollection.

	dbg updateExtensionsFromSession: session.
	self assert: dbg extensionToolNotebook pages size equals: 1.
	self assert: dbg extensionTools size equals: 1.
	self
		assertCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.
	toolPage := dbg extensionToolNotebook pages first.
	self assert: toolPage class identicalTo: SpNotebookPage.
	self
		assert: toolPage presenterProvider value class
		identicalTo: TStDebuggerExtensionTestClass.
	self
		assert: toolPage title
		equals: TStDebuggerExtensionTestClass new debuggerExtensionToolName.
	self
		assert: toolPage presenterProvider value debugger
		identicalTo: dbg.
	self
		assertCollection: dbg extensionTools
		equals: { toolPage presenterProvider value } asOrderedCollection.

	"We deny the context predicate"
	self makeTStDebuggerExtensionTestClassDenyPredicate.

	"The extension is activated and now denies the predicate so it should be hidden in the debugger"
	self assertEmpty: dbg extensionsToDisplay.

	dbg updateExtensionsFromSession: session.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }
]

{ #category : 'tests' }
StDebuggerExtensionMechanismTest >> testExtensionsToDisplayWhenExtensionIsDeactivatedAndNowAcceptsPredicate [

	| dbg session |
	session := StTestDebuggerProvider new sessionForDebuggerTests.
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].
	self enableTStDebuggerExtensionTestClassAsExtension.
	self hideTStDebuggerExtensionTestClass.
	self makeTStDebuggerExtensionTestClassDenyPredicate.

	self deny: TStDebuggerExtensionTestClass showInDebugger.


	dbg := self debugger
		       session: session;
		       application: self debuggerClass currentApplication;
		       initialize;
		       yourself.

	self deny:
		(TStDebuggerExtensionTestClass acceptsPredicate:
			 dbg contextPredicate).

	self assertEmpty: dbg extensionsToDisplay.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }.

	"We accept the context predicate"
	self makeTStDebuggerExtensionTestClassAcceptPredicate.

	"It doesn't matter if the extension accepts the predicate if the extension is deactivated"
	self assertEmpty: dbg extensionsToDisplay.

	dbg updateExtensionsFromSession: session.
	self assertEmpty: dbg extensionTools.
	self assertEmpty: dbg extensionToolNotebook pages.
	self
		denyCollection: dbg stackAndCodeContainer children
		includesAny: { #extensionToolsNotebook }
]

{ #category : 'tests - extensions' }
StDebuggerExtensionMechanismTest >> testHasAnyActivatedExtensions [

	self deny: (self debuggerClass hasAnyActivatedExtension: { TStDebuggerExtensionTestClass }).
	TStDebuggerExtensionTestClass showInDebugger: true.
	self assert: (self debuggerClass hasAnyActivatedExtension: { TStDebuggerExtensionTestClass })
]

{ #category : 'tests - extensions' }
StDebuggerExtensionMechanismTest >> testInstantiateExtensionToolsPage [
	|dbg toolPage|
	dbg := self debugger.
	toolPage := dbg instantiateExtensionToolsPage: StDummyDebuggerPresenter.
	self assert: toolPage class identicalTo: SpNotebookPage.
	self assert: toolPage presenterProvider value class identicalTo: StDummyDebuggerPresenter.
	self assert: toolPage title equals: StDummyDebuggerPresenter new debuggerExtensionToolName.
	self assert: toolPage presenterProvider value debugger identicalTo: dbg.
	self assertCollection: dbg extensionTools includesAll: { toolPage presenterProvider value}.
	 
]

{ #category : 'tests - extensions' }
StDebuggerExtensionMechanismTest >> testRegisterExtensionTool [
	|dbg object|
	dbg := self debugger.
	self assertEmpty: dbg extensionTools.
	dbg registerExtensionTool: (object := Object new).
	self assert: dbg extensionTools size equals: 1.
	self assertCollection: dbg extensionTools equals: { object } asOrderedCollection 
]

{ #category : 'tests - extensions' }
StDebuggerExtensionMechanismTest >> testUsesExtensions [

	| extensionClasses activatedExtension |

	"In case there are no available extensions in the system, we add a test extension to the system.
	We then assume that there is always one extension in the extension collection of the system."
	self enableTStDebuggerExtensionTestClassAsExtension.
	extensionClasses := self debuggerClass extensionToolsClasses.
	self
		assertCollection: extensionClasses
		includesAny: { TStDebuggerExtensionTestClass }.

	"We deactivate all extensions: the debugger should not have any activated extension, 
	and should not use extensions in its layout."
	self debuggerClass extensionToolsClasses do: [ :extension |
		extension showInDebugger: false ].

	self assertEmpty: self debuggerClass activatedDebuggerExtensions.
	self deny: self debuggerClass usesExtensions.

	"We activate the first extension in the extension collection:
	the debugger should have this extension activated, and should use extensions in its layout."
	activatedExtension := extensionClasses asOrderedCollection first.
	activatedExtension showInDebugger: true.
	self
		assertCollection: self debuggerClass activatedDebuggerExtensions
		hasSameElements: { activatedExtension }.
	self assert: self debuggerClass usesExtensions
]
