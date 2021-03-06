#import "EWAppDelegate.h"
#import <EtoileFoundation/EtoileFoundation.h>

#import <CoreObject/CoreObject.h>

#import "EWBranchesWindowController.h"
#import "EWHistoryWindowController.h"
#import "EWUndoWindowController.h"
#import "EWDocument.h"

@implementation EWAppDelegate

#define STOREURL1 [NSURL fileURLWithPath: [@"~/typewriterTest1.typewriter" stringByExpandingTildeInPath]]
#define STOREURL2 [NSURL fileURLWithPath: [@"~/typewriterTest2.typewriter" stringByExpandingTildeInPath]]
#define STOREURL3 [NSURL fileURLWithPath: [@"~/typewriterTest3.typewriter" stringByExpandingTildeInPath]]

- (id) init
{
    SUPERINIT;
    
    // Set up application metamodel
    
    ETEntityDescription *docEntity = [[ETEntityDescription alloc] initWithName: @"TypewriterDocument"];
    {
        [docEntity setParent: (id)@"Anonymous.COObject"];
        
        ETPropertyDescription *paragraphsProperty =
        [ETPropertyDescription descriptionWithName: @"paragraphs" type: (id)@"Anonymous.TypewriterParagraph"];
        [paragraphsProperty setPersistent: YES];
        [paragraphsProperty setMultivalued: YES];
        [paragraphsProperty setOrdered: YES];
        
        [docEntity setPropertyDescriptions: A(paragraphsProperty)];
    }
    
    ETEntityDescription *paragraphEntity = [[ETEntityDescription alloc] initWithName: @"TypewriterParagraph"];
    {
        [paragraphEntity setParent: (id)@"Anonymous.COObject"];
        
        ETPropertyDescription *documentProperty =
        [ETPropertyDescription descriptionWithName: @"document" type: (id)@"Anonymous.TypewriterDocument"];
        [documentProperty setMultivalued: NO];
        [documentProperty setOpposite: (id)@"Anonymous.TypewriterDocument.paragraphs"];
        
        ETPropertyDescription *dataProperty =
        [ETPropertyDescription descriptionWithName: @"data" type: (id)@"Anonymous.NSData"];
        [dataProperty setPersistent: YES];
        
        [paragraphEntity setPropertyDescriptions: A(documentProperty, dataProperty)];
    }
    
    [[ETModelDescriptionRepository mainRepository] addUnresolvedDescription: docEntity];
    [[ETModelDescriptionRepository mainRepository] addUnresolvedDescription: paragraphEntity];
    
    [[ETModelDescriptionRepository mainRepository] resolveNamedObjectReferences];
    
    _user1Ctx = [COEditingContext contextWithURL: STOREURL1];
    _user2Ctx = [COEditingContext contextWithURL: STOREURL2];
    _user3Ctx = [COEditingContext contextWithURL: STOREURL3];
    
    return self;
}

- (COPersistentRoot *) user1PersistentRoot
{
    return [[_user1Ctx persistentRoots] anyObject];
}

- (COPersistentRoot *) user2PersistentRoot
{
    return [[_user2Ctx persistentRoots] anyObject];
}

- (COPersistentRoot *) user3PersistentRoot
{
    return [[_user3Ctx persistentRoots] anyObject];
}

- (void) applicationDidFinishLaunching: (NSNotification*)notif
{
    [[EWBranchesWindowController sharedController] showWindow: self];
    [[EWHistoryWindowController sharedController] showWindow: self];
    
    COPersistentRoot *user1Proot = nil;
    COPersistentRoot *user2Proot = nil;
    COPersistentRoot *user3Proot = nil;
	
    if ([[_user1Ctx persistentRoots] isEmpty])
    {
        user1Proot = [_user1Ctx insertNewPersistentRootWithEntityName: @"Anonymous.TypewriterDocument"];
        [_user1Ctx commit];
        
        COSynchronizationClient *client = [[COSynchronizationClient alloc] init];
        COSynchronizationServer *server = [[COSynchronizationServer alloc] init];
        
		{
			id request2 = [client updateRequestForPersistentRoot: [user1Proot UUID]
														serverID: @"server"
														   store: [_user2Ctx store]];
			id response2 = [server handleUpdateRequest: request2 store: [_user1Ctx store]];
			[client handleUpdateResponse: response2 store: [_user2Ctx store]];
			
			user2Proot = [_user2Ctx persistentRootForUUID: [user1Proot UUID]];
			assert(user2Proot != nil);
		}
		
		{
			id request2 = [client updateRequestForPersistentRoot: [user1Proot UUID]
														serverID: @"server"
														   store: [_user3Ctx store]];
			id response2 = [server handleUpdateRequest: request2 store: [_user1Ctx store]];
			[client handleUpdateResponse: response2 store: [_user3Ctx store]];
			
			user3Proot = [_user3Ctx persistentRootForUUID: [user1Proot UUID]];
			assert(user3Proot != nil);
		}
    }
    else
    {
        assert([[_user1Ctx persistentRoots] count] == 1);
        assert([[_user2Ctx persistentRoots] count] == 1);
		assert([[_user3Ctx persistentRoots] count] == 1);
        user1Proot = [[_user1Ctx persistentRoots] anyObject];
        user2Proot = [[_user2Ctx persistentRoots] anyObject];
        user3Proot = [[_user3Ctx persistentRoots] anyObject];
    }
    assert([[user1Proot UUID] isEqual: [user2Proot UUID]]);
    assert([[user1Proot UUID] isEqual: [user3Proot UUID]]);
    
    for (NSDictionary *dict in @[@{@"proot" : user1Proot, @"title" : @"user1"},
                                 @{@"proot" : user2Proot, @"title" : @"user2"},
								 @{@"proot" : user3Proot, @"title" : @"user3"}])
    {
        EWDocument *doc = [[EWDocument alloc] initWithPersistentRoot: dict[@"proot"] title: dict[@"title"]];
        [[NSDocumentController sharedDocumentController] addDocument: doc];
        [doc makeWindowControllers];
        [doc showWindows];
    }
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
}

-(void)undoHistory:(id)sender
{
    [[EWUndoWindowController sharedController] showWindow: self];
}

@end
