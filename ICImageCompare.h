//
//  ICImageCompare.h
//  SMKImageCompare
//
//  Created by Anton Kushpil on 9/28/15.
//  Copyright © 2015 Anton Kushpil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


CGImageRef CGImageRefFromPath(NSString *testImagePath);

CGContextRef CreateContextOfSizeWithData(CGSize size,
                                         unsigned char **data);

BOOL ImageCompare(NSString *directoryPath,
                  NSString *imageName,
                  CGImageRef *firstImage,
                  CGImageRef *secondImage,
                  NSString **error);

BOOL CompareTwoImages(CGImageRef *firstImage,
                      CGImageRef *secondImage,
                      NSString *directoryPath,
                      CGImageRef *diff);

BOOL SaveImageToDirectory(NSString *imageName,
                          NSString *saveDirectory,
                          CGImageRef *saveImage);

BOOL almostEqual(unsigned char a, unsigned char b);

NSData* CGImageWriteToFile(CGImageRef image);