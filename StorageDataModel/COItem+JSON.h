/**
    Copyright (C) 2013 Eric Wasylishen

    Date:  July 2013
    License:  MIT  (see COPYING)
 */

#import <CoreObject/COItem.h>

// HACK: Used by graphviz to pretty-print types
NSString * COJSONTypeToString(COType type);

/**
 * @group Storage Data Model
 * @abstract
 * COItem JSON Serialization.
 */
@interface COItem (JSON)

/**
 * Returns a JSON object representation of the receiver, encoded as UTF-8.
 */
- (NSData *) JSONData;
/**
 * Returns a plist form of the JSON serialization, suitable for converting to 
 * JSON bytes using NSJSONSerialization.
 */
- (id) JSONPlist;
/**
 * Initializes a COItem with the given JSON serialization, generated by -JSONData.
 */
- (id) initWithJSONData: (NSData *)data;
/**
 * Initializes a COItem with the given JSON serialization, generated by -JSONPlist.
 */
- (id) initWithJSONPlist: (id)aPlist;

@end
