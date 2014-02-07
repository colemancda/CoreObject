/*
    Copyright (C) 2014 Eric Wasylishen
 
    Date:  February 2014
    License:  MIT  (see COPYING)
 */

#import "EWAppDelegate.h"
#import "EWDocument.h"
#import "EWUndoManager.h"
#import "EWTypewriterWindowController.h"
#import <EtoileFoundation/Macros.h>

#import <CoreObject/CoreObject.h>
#import <CoreObject/COEditingContext+Private.h>

@implementation EWDocument

@synthesize editingContext = ctx;
@synthesize libraryPersistentRoot = library;

#pragma mark - initialization

- (instancetype) initWithStoreURL: (NSURL *)aURL
{
	self = [super init];
	
    ctx = [COEditingContext contextWithURL: aURL];
	
	NSSet *libraryPersistentRoots = [[ctx persistentRoots] filteredSetUsingPredicate:
									 [NSPredicate predicateWithBlock: ^(id object, NSDictionary *bindings)
									  {
										  COPersistentRoot *persistentRoot = object;
										  return [[persistentRoot rootObject] isKindOfClass: [COLibrary class]];
									  }]];
	
	if ([libraryPersistentRoots count] == 0)
	{
		library = [ctx insertNewPersistentRootWithEntityName: @"COTagLibrary"];
		
		// Create a default tag group
		COTagGroup *defaultTagGroup = [[COTagGroup alloc] initWithObjectGraphContext: library.objectGraphContext];
		defaultTagGroup.name = @"Default Tag Group";
		[(COTagLibrary *)library.rootObject setTagGroups: @[defaultTagGroup]];
		
		[ctx commit];
	}
	else if ([libraryPersistentRoots count] == 1)
	{
		library = [libraryPersistentRoots anyObject];
	}
	else
	{
		[NSException raise: NSGenericException format: @"Expected only a single library"];
	}
	
	NSLog(@"Library is %@", library);

	return self;
}

- (id)init
{
    [NSException raise: NSIllegalSelectorException format: @"use -initWithPersistentRoot:, not -init"];
    return nil;
}

#pragma mark - NSDocument overrides

- (void)makeWindowControllers
{
    EWTypewriterWindowController *windowController = [[EWTypewriterWindowController alloc] initWithWindowNibName: [self windowNibName]];
    [self addWindowController: windowController];
}

- (NSString *)windowNibName
{
    return @"Document";
}

@end
