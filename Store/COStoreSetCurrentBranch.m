#import "COStoreSetCurrentBranch.h"
#import "COSQLiteStore+Private.h"

@implementation COStoreSetCurrentBranch

@synthesize branch, persistentRoot;

- (BOOL) execute: (COSQLiteStore *)store inTransaction: (COStoreTransaction *)aTransaction
{
    return [[store database] executeUpdate: @"UPDATE persistentroots SET currentbranch = ? WHERE uuid = ?",
            [branch dataValue], [persistentRoot dataValue]];
}

@end
