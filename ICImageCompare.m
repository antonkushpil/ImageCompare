//
//  ICImageCompare.m
//  SMKImageCompare
//
//  Created by Anton Kushpil on 9/28/15.
//  Copyright © 2015 Anton Kushpil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICImageCompare.h"
#import <CoreServices/CoreServices.h>
#import <ImageIO/ImageIO.h>


//  Creating CGImageRef images

CGImageRef CGImageRefFromPath(NSString* testImagePath)
{
    // Creating CGImagrRef
    NSURL *testImageURL = [NSURL fileURLWithPath:testImagePath];
    
    CGImageRef        testImage = NULL;
    CGImageSourceRef  imageSource;
    CFDictionaryRef   options = NULL;
    CFStringRef       keys[2];
    CFTypeRef         values[2];
    
    // Set up options if you want them. The options here are for
    // caching the image in a decoded form and for using floating-point
    // values if the image format supports them.
    keys[0] = kCGImageSourceShouldCache;
    values[0] = (CFTypeRef)kCFBooleanTrue;
    keys[1] = kCGImageSourceShouldAllowFloat;
    values[1] = (CFTypeRef)kCFBooleanTrue;
    // Create the dictionary
    options = CFDictionaryCreate(NULL, (const void **) keys,
                                   (const void **) values, 2,
                                   &kCFTypeDictionaryKeyCallBacks,
                                   & kCFTypeDictionaryValueCallBacks);
    // Create an image source from the URL.
    imageSource = CGImageSourceCreateWithURL((CFURLRef)testImageURL, options);
    CFRelease(options);
    // Create an image from the first item in the image source.
    testImage = CGImageSourceCreateImageAtIndex(imageSource,
                                                 0,
                                                 NULL);
    CFRelease(imageSource);
    
    return testImage;
}

// Compare two images

BOOL ImageCompare(NSString *directoryPath,
                  NSString *imageName,
                  CGImageRef *firstImage,
                  CGImageRef *secondImage,
                  NSString **error)
{
    NSString *failString = nil;
    if (error)
    {
        *error = nil;
    }
    BOOL result = YES;
            NSString *aPath = directoryPath;
            CGImageRef diff = nil;
            result = aPath != nil;
            if (result)
            {
                result = CompareTwoImages(firstImage,
                                          secondImage,
                                          directoryPath,
                                          &diff);
            }
            if (!result)
            {
                if (aPath)
                {
                    imageName = [imageName stringByAppendingString:@"_Failed"];
                }
                BOOL aSaved = SaveImageToDirectory(imageName, directoryPath, firstImage);
                NSString *fileNameWithExtension = [imageName stringByAppendingString:@".png"];
                NSString *fullSavePath = [directoryPath stringByAppendingPathComponent:fileNameWithExtension];
                
                if (NO == aSaved)
                {
                    if (!aPath)
                    {
                        failString = [NSString stringWithFormat:@"File %@ did not exist in "
                                      @"bundle. Tried to save as %@ and failed.",
                                      fileNameWithExtension, fullSavePath];
                    }
                    else
                    {
                        failString = [NSString stringWithFormat:@"Object image different "
                                      @"than file %@. Tried to save as %@ and failed.",
                                      aPath, fullSavePath];
                    }
                }
                else
                {
                    if (!aPath)
                    {
                        failString = [NSString stringWithFormat:@"File %@ did not exist in "
                                      @" bundle. Saved to %@", fileNameWithExtension,
                                      fullSavePath];
                    }
                    else
                    {
                        NSString *diffPath = [imageName stringByAppendingString:@"_Diff"];
                        diffPath = [directoryPath stringByAppendingPathComponent:diffPath];
                        diffPath = [diffPath stringByAppendingPathExtension:@"png"];
                        NSData *data = nil;
                        if (diff)
                        {
                            data = CGImageWriteToFile(diff);
                        }
                        if ([data writeToFile:diffPath atomically:YES])
                        {
                            failString = [NSString stringWithFormat:@"Object image different "
                                          @"than file\n%@\nSaved image to\n%@\n"
                                          @"Saved diff to\n%@\n",
                                          aPath, fullSavePath, diffPath];
                        }
                        else
                        {
                            failString = [NSString stringWithFormat:@"Object image different "
                                          @"than file\n%@\nSaved image to\n%@\nUnable to save "
                                          @"diff. Most likely the image and diff are "
                                          @"different sizes.",
                                          aPath, fullSavePath];
                        }
                    }
                }
            }
            CGImageRelease(diff);
        if (firstImage == nil)
        {
            failString = @"Testing a nil image.";
        }
    if (error)
    {
        *error = failString;
    }
    return result;
}

// Image compare process

BOOL CompareTwoImages(CGImageRef *firstImage,
                      CGImageRef *secondImage,
                      NSString *directoryPath,
                      CGImageRef *diff)
{
    BOOL answer = NO;
    if (diff)
    {
        *diff = nil;
    }
    
    CGImageRef fileRep = *firstImage;
    CGImageRef imageRep = *secondImage;
    
    size_t fileHeight = CGImageGetHeight(fileRep);
    size_t fileWidth = CGImageGetWidth(fileRep);
    size_t imageHeight = CGImageGetHeight(imageRep);
    size_t imageWidth = CGImageGetWidth(imageRep);
    if (fileHeight == imageHeight && fileWidth == imageWidth)
    {
        // if all the sizes are equal, run through the bytes and compare
        // them for equality.
        // Do an initial fast check, if this fails and the caller wants a
        // diff, we'll do the slow path and create the diff. The diff path
        // could be optimized, but probably not necessary at this point.
        answer = YES;
        
        CGSize imageSize = CGSizeMake(fileWidth, fileHeight);
        CGRect imageRect = CGRectMake(0, 0, fileWidth, fileHeight);
        unsigned char *fileData;
        unsigned char *imageData;
        CGContextRef fileContext
        = CreateContextOfSizeWithData(imageSize, &fileData);
        CGContextDrawImage(fileContext, imageRect, fileRep);
        CGContextRef imageContext
        = CreateContextOfSizeWithData(imageSize, &imageData);
        CGContextDrawImage(imageContext, imageRect, imageRep);
        
        size_t fileBytesPerRow = CGBitmapContextGetBytesPerRow(fileContext);
        size_t imageBytesPerRow = CGBitmapContextGetBytesPerRow(imageContext);
        size_t row, col;
        
        for (row = 0; row < fileHeight && answer; row++)
        {
            answer = memcmp(fileData + fileBytesPerRow * row,
                            imageData + imageBytesPerRow * row,
                            imageWidth * 4) == 0;
        }
        if (!answer && diff)
        {
            answer = YES;
            unsigned char *diffData;
            CGContextRef diffContext
            = CreateContextOfSizeWithData(imageSize, &diffData);
            size_t diffRowBytes = CGBitmapContextGetBytesPerRow(diffContext);
            for (row = 0; row < imageHeight; row++) {
                uint32_t *imageRow = (uint32_t*)(imageData + imageBytesPerRow * row);
                uint32_t *fileRow = (uint32_t*)(fileData + fileBytesPerRow * row);
                uint32_t* diffRow = (uint32_t*)(diffData + diffRowBytes * row);
                for (col = 0; col < imageWidth; col++) {
                    uint32_t imageColor = imageRow[col];
                    uint32_t fileColor = fileRow[col];
                    
                    unsigned char imageAlpha = imageColor & 0xF;
                    unsigned char imageBlue = imageColor >> 8 & 0xF;
                    unsigned char imageGreen = imageColor >> 16 & 0xF;
                    unsigned char imageRed = imageColor >> 24 & 0xF;
                    unsigned char fileAlpha = fileColor & 0xF;
                    unsigned char fileBlue = fileColor >> 8 & 0xF;
                    unsigned char fileGreen = fileColor >> 16 & 0xF;
                    unsigned char fileRed = fileColor >> 24 & 0xF;
                    
                    // Check to see if color is almost right.
                    // No matter how hard I've tried, I've still gotten occasionally
                    // screwed over by colorspaces not mapping correctly, and small
                    // sampling errors coming in. This appears to work for most cases.
                    // Almost equal is defined to check within 1% on all components.
                    BOOL equal = almostEqual(imageRed, fileRed) &&
                    almostEqual(imageGreen, fileGreen) &&
                    almostEqual(imageBlue, fileBlue) &&
                    almostEqual(imageAlpha, fileAlpha);
                    answer &= equal;
                    if (diff)
                    {
                        uint32_t newColor;
                        if (equal)
                        {
                            newColor = (((uint32_t)imageRed) << 24) +
                            (((uint32_t)imageGreen) << 16) +
                            (((uint32_t)imageBlue) << 8) +
                            (((uint32_t)imageAlpha) / 2);
                        }
                        else
                        {
                            newColor = 0xFF0000FF;
                        }
                        diffRow[col] = newColor;
                    }
                }
            }
            *diff = CGBitmapContextCreateImage(diffContext);
            free(diffData);
            CFRelease(diffContext);
        }
        free(fileData);
        CFRelease(fileContext);
        free(imageData);
        CFRelease(imageContext);
    }
    return answer;
}

// Save Image

BOOL SaveImageToDirectory(NSString *imageName,
                          NSString *saveDirectory,
                          CGImageRef *saveImage)
{
    NSString *resultsDirectory = [[NSString alloc] initWithString:saveDirectory];
    resultsDirectory = [resultsDirectory stringByAppendingPathComponent:imageName];
    resultsDirectory = [resultsDirectory stringByAppendingPathExtension:@"png"];
    
    NSLog(@"%@", resultsDirectory);
    
    NSData *data = CGImageWriteToFile(*saveImage);
    
    return [data writeToFile:resultsDirectory atomically:YES];
}

// Contex from data

CGContextRef CreateContextOfSizeWithData(CGSize size,
                                         unsigned char **data)
{
    CGContextRef context = NULL;
    size_t height = size.height;
    size_t width = size.width;
    size_t bytesPerRow = width * 4;
    size_t bitsPerComponent = 8;
    CGColorSpaceRef cs = NULL;

    cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    CGBitmapInfo info
    = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
    if (data)
    {
        *data = (unsigned char*)calloc(bytesPerRow, height);
    }
    context = CGBitmapContextCreate(data ? *data : NULL, width, height,
                                    bitsPerComponent, bytesPerRow, cs, info);
    if (!data)
    {
        CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
    }
    CGContextSetRenderingIntent(context, kCGRenderingIntentRelativeColorimetric);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);
    CGContextSetShouldSmoothFonts(context, NO);
    CGColorSpaceRelease(cs);
    
    return context;
}

// Small utility function for checking to see if a is b +/- 1.

BOOL almostEqual(unsigned char a, unsigned char b)
{
    unsigned char diff = a > b ? a - b : b - a;
    BOOL notEqual = diff < 2;
    return notEqual;
}

// Taking Data from CGImageRef

NSData* CGImageWriteToFile(CGImageRef image)
{
    NSData *data = [NSMutableData data];
    CGImageDestinationRef dest
    = CGImageDestinationCreateWithData((CFMutableDataRef)data,
                                       kUTTypePNG,
                                       1,
                                       NULL);
    NSDictionary *tiffDict
    = [NSDictionary dictionaryWithObjectsAndKeys:
       [[NSNumber alloc] initWithUnsignedInteger:NSTIFFCompressionLZW],
       (const NSString*)kCGImagePropertyTIFFCompression,
       nil];
    NSDictionary *destProps
    = [NSDictionary dictionaryWithObjectsAndKeys:
       [NSNumber numberWithFloat:1.0f],
       (const NSString*)kCGImageDestinationLossyCompressionQuality,
       tiffDict,
       (const NSString*)kCGImagePropertyTIFFDictionary,
       nil];
    CGImageDestinationAddImage(dest, image, (CFDictionaryRef)destProps);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    
    return data;
}
