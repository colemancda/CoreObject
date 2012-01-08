/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  December 2011
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class COObject, CORevision;
@class COTrackNode;

/** 
 * @group History Navigation
 *
 * COTrack is an abstract class to represent a commit sequence, that can be 
 * persistent or lazily constructed (this depends on the subclass).
 *
 * A track provides a custom view on the history graph that describes the 
 * relations between the persistent object revisions. Each node in the history 
 * graph is a commit or revision.
 *
 * Each track refers to commits or revisions indirectly through COTrackNode 
 * rather CORevision. Hence a track is a track node collection, where every node 
 * is a simple wrapper around a revision object. A track node allows to know to 
 * which track a revision object belongs to.
 */
@interface COTrack : NSObject <ETCollection>
{
	@private
	NSMutableArray *cachedNodes;
	@protected
	// TODO: Would be better to make the ivar below private rather than 
	// protected but this makes the code much more verbose in subclasses.
	NSInteger currentNodeIndex;
}

/** @taskunit Initialization */

+ (id)trackWithObject: (COObject *)anObject;
/**
 * <init />
 */
- (id)initWithTrackedObjects: (NSSet *)objects;

/** @taskunit Tracked Objects */

/**
 * <override-subclass />
 * The tracked objects.
 *
 * By default, returns an empty set.
 */
@property (readonly, nonatomic) NSSet *trackedObjects;

/** @taskunit Track Nodes */

/**
 * Returns the current track node that reflects the current position in the 
 * the track timeline. 
 */
- (COTrackNode *)currentNode;
/**
 * <override-subclass />
 * Sets the current position in the the track timeline to match the track node.
 */
- (void)setCurrentNode: (COTrackNode *)node;

/**
 * Returns the cached track nodes. 
 */
- (NSMutableArray *)cachedNodes;

/** @task Undo Management */

/**
 * <override-subclass />
 * Moves backward on the track to undo.
 *
 * An undo corresponds to changing the current track node to some previous node. 
 * What <em>previous</em> means precisely is up to the track subclass.
 */
- (void)undo;
/**
 * <override-subclass />
 * Moves forward on the track to redo.
 *
 * A redo corresponds to changing the current track node to some next node. 
 * What <em>next</em> means precisely is up to the track subclass.
 */
- (void)redo;

@end


@interface COTrackNode : NSObject
{
	@private
	CORevision *revision;
	COTrack *track;
}

/** @taskunit Initialization */

+ (id)nodeWithRevision: (CORevision *)aRevision onTrack: (COTrack *)aTrack;

/** <init /> */
- (id)initWithRevision: (CORevision *)rev onTrack: (COTrack *)aTrack;

/** @taskunit Basic Properties */

/**
 * Returns the revision wrapped by the track node.
 */
- (CORevision *)revision;
/**
 * Returns the track that owns the receiver.
 */
- (COTrack *)track;

/** @taskunit Metadata */

- (NSDictionary *)metadata;
- (uint64_t)revisionNumber;
- (ETUUID *)UUID;
- (NSArray *)changedObjectUUIDs;

@end