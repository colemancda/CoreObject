/*
    Copyright (C) 2013 Eric Wasylishen

    Date:  December 2013
    License:  MIT  (see COPYING)
 */

#import "OrderedGroupContent.h"

@implementation OrderedGroupContent

+ (ETEntityDescription*)newEntityDescription
{
    ETEntityDescription *entity = [ETEntityDescription descriptionWithName: @"OrderedGroupContent"];
    [entity setParent: (id)@"Anonymous.COObject"];
	
    ETPropertyDescription *labelProperty = [ETPropertyDescription descriptionWithName: @"label"
                                                                                 type: (id)@"Anonymous.NSString"];
    [labelProperty setPersistent: YES];
	
	ETPropertyDescription *parentGroupsProperty = [ETPropertyDescription descriptionWithName: @"parentGroups"
																						type: (id)@"Anonymous.OrderedGroupWithOpposite"];
    [parentGroupsProperty setMultivalued: YES];
    [parentGroupsProperty setOrdered: NO];
	[parentGroupsProperty setOpposite: (id)@"Anonymous.OrderedGroupWithOpposite.contents"];
	[parentGroupsProperty setDerived: YES];
	
	[entity setPropertyDescriptions: @[labelProperty, parentGroupsProperty]];
	
    return entity;
}

@dynamic label;
@dynamic parentGroups;
@end
