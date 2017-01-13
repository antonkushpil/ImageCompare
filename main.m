//
//  main.m
//  SMKImageCompare
//
//  Created by Anton Kushpil on 9/28/15.
//  Copyright © 2015 Anton Kushpil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ICImageCompare.h"


int main(int argc, const char * argv[]) {
    
    NSString *directoryPath = @"/Users/antonkushpil/Documents/Test";
    NSString *testImageName = @"Screen";
    NSString *imageNameWithFormat = [testImageName stringByAppendingString:@".png"];
    NSString *firstImagePath = [NSString pathWithComponents:@[directoryPath, imageNameWithFormat]];
    NSString *secondImagePath = [NSString pathWithComponents:@[directoryPath, @"Run 1", imageNameWithFormat]];
    
    CGImageRef firstImage = CGImageRefFromPath(firstImagePath);
    CGImageRef secondImage = CGImageRefFromPath(secondImagePath);
    
    directoryPath = [directoryPath stringByAppendingPathComponent:@"TestResults"];
    
    BOOL result = ImageCompare(directoryPath, testImageName, &firstImage, &secondImage, nil);
    
    
    return result;
}
