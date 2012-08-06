//
//  FileOperations.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FileOperations.h"

@implementation FileOperations

// Returns the contents of the files in the cache folder in reverse order
+ (NSArray *)filesInReverseDateOrder:(NSString *)folderPath
{
    NSMutableArray *returnedFiles = [[[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil] mutableCopy];
    
    // now sort by country, city, state (in that order)
    
    // The arguments to the block are two objects to compare.
    // The block returns an NSComparisonResult value to denote the ordering of the two objects.
    
    [returnedFiles sortUsingComparator:^NSComparisonResult(id element1, id element2){
        
        NSComparisonResult result;
        
        // If either of these are not dictionaries, then something catastrophic has happened
        assert([element1 isKindOfClass:[NSString class]]);
        assert([element2 isKindOfClass:[NSString class]]);
        
        // use NSDictionary so as we don't need to cast in calls
        NSDictionary *file1Dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:element1] error:nil];
        NSDictionary *file2Dictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:element2] error:nil];
        
        NSDate *modification1Date = [file1Dictionary fileModificationDate];
        NSDate *modification2Date = [file2Dictionary fileModificationDate];
        
        // REVERSE order - so newest file is 1st
        result =  [modification2Date compare:modification1Date];
        
        // Now return the result of the compare.
        return result;
    }];
    return returnedFiles;
}

// Returns the size of a given folder
+ (NSUInteger)folderSize:(NSString *)folderPath
{
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    NSUInteger fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    return fileSize;
}
@end