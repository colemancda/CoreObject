/*
	Copyright (C) 2013 Eric Wasylishen
 
	Date:  December 2013
	License:  MIT  (see COPYING)
 */

#import "COAttributedStringWrapper.h"
#import "COAttributedString.h"
#import "COAttributedStringChunk.h"
#import "COAttributedStringAttribute.h"

@interface COAttributedStringWrapper ()

@end

@implementation COAttributedStringWrapper

@synthesize backing = _backing;

- (instancetype) initWithBacking: (COAttributedString *)aBacking
{
	NILARG_EXCEPTION_TEST(aBacking);
	
	SUPERINIT;
	_lastNotifiedLength = [aBacking length];
	_backing = aBacking;
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(objectGraphContextObjectsDidChangeNotification:)
												 name: COObjectGraphContextObjectsDidChangeNotification
											   object: aBacking.objectGraphContext];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) objectGraphContextObjectsDidChangeNotification: (NSNotification *)notif
{
	if (_inPrimitiveMethod)
		return;
	
	NSUInteger currentLength = [self length];
	NSInteger delta = (NSInteger)currentLength - _lastNotifiedLength;
	NSUInteger oldLength = _lastNotifiedLength;
	_lastNotifiedLength = currentLength;
	
	NSLog(@"Last time -edited:range:changeInLength: was called, length was %d. Changed by %d", (int)_lastNotifiedLength, (int)delta);

	[self edited: NSTextStorageEditedAttributes | NSTextStorageEditedCharacters
		   range: NSMakeRange(0, oldLength)
  changeInLength: delta];
}

// Primitive NSAttributedString methods

- (NSString *)string
{
	return [_backing string];
}

- (NSDictionary *)attributesAtIndex: (NSUInteger)anIndex effectiveRange: (NSRangePointer)aRangeOut
{
	_inPrimitiveMethod = YES;
	
	// TODO: What should the attributes be at the end of the string?
	
	NSUInteger chunkIndex = 0, chunkStart = 0;
	COAttributedStringChunk *target = [self.backing chunkContainingIndex: anIndex chunkStart: &chunkStart chunkIndex: &chunkIndex];
	
	if (target != nil)
	{
		if (aRangeOut != NULL)
		{
			*aRangeOut = NSMakeRange(chunkStart, target.length);
		}
		
		NSMutableDictionary *result = [NSMutableDictionary new];
		
		NSFont *font = [NSFont userFontOfSize: 12];
		
		for (COAttributedStringAttribute *attr in target.attributes)
		{
			if ([attr.htmlCode isEqualToString: @"b"])
			{
				font = [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: NSFontBoldTrait];
			}
			if ([attr.htmlCode isEqualToString: @"i"])
			{
				font = [[NSFontManager sharedFontManager] convertFont: font toHaveTrait: NSFontItalicTrait];
			}
			if ([attr.htmlCode isEqualToString: @"u"])
			{
				result[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
			}
		}
		
		result[NSFontAttributeName] = font;
		
		_inPrimitiveMethod = NO;
		return result;
	}
	
	_inPrimitiveMethod = NO;
	return nil;
}

// Primitive NSMutableAttributedString methods

- (void)replaceCharactersInRange: (NSRange)aRange withString: (NSString *)aString
{
	_inPrimitiveMethod = YES;
		
	NSUInteger chunkIndex = 0, chunkStart = 0;
	COAttributedStringChunk *chunk = [_backing chunkContainingIndex: aRange.location chunkStart: &chunkStart chunkIndex: &chunkIndex];
	
	/* Sepecial case: empty string */
	if ([_backing.chunks count] == 0)
	{
		chunk = [[COAttributedStringChunk alloc] initWithObjectGraphContext: _backing.objectGraphContext];
		chunk.text = @"";
		_backing.chunks = @[chunk];
	}
	
	/* Special case: inserting at end of string */
	if (chunk == nil && aRange.location == [self length])
	{
		ETAssert([self length] > 0);
		chunk = [_backing chunkContainingIndex: aRange.location - 1 chunkStart: &chunkStart chunkIndex: &chunkIndex];
	}
	
	ETAssert(chunk != nil);
	const NSUInteger chunkLength = [[chunk text] length];
	
	const NSUInteger indexInChunk = aRange.location - chunkStart;
	NSUInteger lengthInChunkToReplace = aRange.length;
	if (indexInChunk + lengthInChunkToReplace > chunkLength)
	{
		lengthInChunkToReplace = chunkLength - indexInChunk;
	}
	
	NSString *newText = [chunk.text stringByReplacingCharactersInRange: NSMakeRange(indexInChunk, lengthInChunkToReplace) withString: aString];
	chunk.text = newText;
	
	NSUInteger remainingLengthToDelete = aRange.length - lengthInChunkToReplace;
	
	while (remainingLengthToDelete > 0)
	{
		// Scan forward through the following chunks, trimming text as needed

		chunk = _backing.chunks[++chunkIndex];

		lengthInChunkToReplace = MIN([[chunk text] length], remainingLengthToDelete);
		chunk.text = [chunk.text stringByReplacingCharactersInRange: NSMakeRange(0, lengthInChunkToReplace) withString: @""];
		remainingLengthToDelete -= lengthInChunkToReplace;
	}
	
	// TODO: Add tests that check for this
	[self edited: NSTextStorageEditedCharacters range: aRange changeInLength: [aString length] - aRange.length];
	
	_inPrimitiveMethod = NO;
}

- (COAttributedStringAttribute *) makeAttr: (NSString *)htmlCode
{
	COAttributedStringAttribute *attribute = [[COAttributedStringAttribute alloc] initWithObjectGraphContext: [_backing objectGraphContext]];
	attribute.htmlCode = htmlCode;
	return attribute;
}

- (void)setAttributes:(NSDictionary *)attrs forChunk: (COAttributedStringChunk *)aChunk
{
	NSMutableSet *newAttribs = [NSMutableSet new];
	
	for (NSString *attributeName in attrs)
	{
		id attributeValue = attrs[attributeName];
		
		if ([attributeName isEqual: NSUnderlineStyleAttributeName] && [attributeValue isEqual: @(NSUnderlineStyleSingle)])
		{
			[newAttribs addObject: [self makeAttr: @"u"]];
		}
		else if ([attributeName isEqual: NSFontAttributeName])
		{
			NSFont *font = attributeValue;
			NSFontSymbolicTraits traits = [[font fontDescriptor] symbolicTraits];
			if ((traits & NSFontBoldTrait) == NSFontBoldTrait)
			{
				[newAttribs addObject: [self makeAttr: @"b"]];
			}
			if ((traits & NSFontItalicTrait) == NSFontItalicTrait)
			{
				[newAttribs addObject: [self makeAttr: @"i"]];
			}
		}
	}
	
	aChunk.attributes = newAttribs;
}

- (void)setAttributes: (NSDictionary *)aDict range: (NSRange)aRange
{
	if (aRange.length == 0)
	{
		return;
	}
	
	_inPrimitiveMethod = YES;
	
	// TODO: We could avoid splitting if the given range already has exactly
	// the right attributes
	
	const NSUInteger splitChunk1 = [_backing splitChunkAtIndex: aRange.location];
	const NSUInteger splitChunk2 = [_backing splitChunkAtIndex: NSMaxRange(aRange)];
	
	ETAssert(splitChunk2 > splitChunk1);
	
	// Set all chunks from splitChunk1, up to but not including splitChunk2, to
	// have the attributes in aDict
	
	for (NSUInteger i = splitChunk1; i < splitChunk2; i++)
	{
		COAttributedStringChunk *chunk = _backing.chunks[i];
		[self setAttributes: aDict forChunk: chunk];
	}
	
	// TODO: Add tests that check for this
	[self edited: NSTextStorageEditedAttributes range: aRange changeInLength: 0];
	
	_inPrimitiveMethod = NO;
}

@end
