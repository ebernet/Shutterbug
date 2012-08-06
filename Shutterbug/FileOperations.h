//
//  FileOperations.h
//  Helper methods for file management - returns
//  the size of a folder's contents, and a list of file
//  names in a folder in reverse modification order
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileOperations : NSObject
+ (NSArray *)filesInReverseDateOrder:(NSString *)folderPath;
+ (NSUInteger)folderSize:(NSString *)folderPath;
@end
