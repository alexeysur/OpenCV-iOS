//
//  OpenCVWrapper.h
//  CustomCamera
//
//  Created by Alexey on 05.04.2023.
//  Copyright © 2023 ca.alexs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

- (void)isThisWorking;
- (BOOL)isImageBlurry:(UIImage *) image;
- (UIImage *)checkForBlurryImage:(UIImage *) image;

@end

NS_ASSUME_NONNULL_END
