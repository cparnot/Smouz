//  Smouz
//  Created by Charles Parnot on 9/30/15.
//  Licensed under the terms of the modified BSD License, as specified in the file 'LICENSE-BSD.txt' included with this distribution


#import <AppKit/AppKit.h>

@interface NSBezierPath (Smouz)

// recommended tightness: 3.0
+ (instancetype)bezierPathForSmoothedFunctionWithPoints:(NSArray *)points tightness:(CGFloat)tightness bounds:(NSRect)bounds;

@end
