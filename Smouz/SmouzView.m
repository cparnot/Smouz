//  Smouz
//  Created by Charles Parnot on 8/10/14.
//  Licensed under the terms of the modified BSD License, as specified in the file 'LICENSE-BSD.txt' included with this distribution


#import "SmouzView.h"
#import "NSBezierPath+Smouz.h"

@implementation SmouzView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    self.data = @[
                  @{ @"x" : @(  0.0), @"y" : @(  0.0) }.mutableCopy,
                  @{ @"x" : @( 50.0), @"y" : @( 50.0) }.mutableCopy,
                  @{ @"x" : @(100.0), @"y" : @(100.0) }.mutableCopy,
                  ];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)userDefaultsDidChange:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // transform to fit things in the view
    // path is supposed to fit in 100. x 100.0, so we'll make it fit in the bounds with padding
    CGFloat padding = 30.0;
    NSRect targetRect = NSInsetRect(self.bounds, padding, padding);
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:padding yBy:padding];
    [transform scaleXBy:targetRect.size.width / 100.0 yBy:targetRect.size.height / 100.0];

    // draw the background
    NSBezierPath *viewBounds = [NSBezierPath bezierPathWithRect:NSInsetRect(self.bounds, 0.5, 0.5)];
    [[NSColor whiteColor] setFill];
    [viewBounds fill];
    NSBezierPath *graphBounds = [NSBezierPath bezierPathWithRect:targetRect];
    [[NSColor colorWithCalibratedWhite:0.97 alpha:1.0] setFill];
    [[NSColor colorWithCalibratedWhite:0.90 alpha:1.0] setStroke];
    [graphBounds fill];
    [graphBounds stroke];

    // transform the points to pass to Smouz
    NSMutableArray *points = [NSMutableArray array];
    for (NSDictionary *dic in self.data)
    {
        NSPoint A = NSMakePoint([dic[@"x"] floatValue], [dic[@"y"] floatValue]);
        [points addObject:[NSValue valueWithPoint:A]];
    }
    
    // get the smoothed curve
    CGFloat tightness =[[NSUserDefaults standardUserDefaults] floatForKey:@"CurveTightness"];
    BOOL shouldConstrainBounds = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShouldConstrainBounds"];
    NSRect smouzBounds = NSMakeRect(0.0, 0.0, 100.0, 100.0);
    NSBezierPath *smouz = [NSBezierPath bezierPathForSmoothedFunctionWithPoints:points.copy tightness:tightness bounds:shouldConstrainBounds ? smouzBounds : NSZeroRect];
    
    // draa the control points
    [[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] setFill];
    [[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] setStroke];
    NSUInteger max = smouz.elementCount;
    for (NSUInteger i = 1; i < max; i++)
    {
        NSPoint curvePoints[3] = { NSMakePoint(0.0, 0.0), NSMakePoint(0.0, 0.0), NSMakePoint(0.0, 0.0) };
        [smouz elementAtIndex:i associatedPoints:curvePoints];
        
        // control points
        NSPoint A2 = [transform transformPoint:curvePoints[0]];
        NSPoint A3 = [transform transformPoint:curvePoints[1]];
        NSRect A2Circle = NSInsetRect(NSMakeRect(A2.x, A2.y, 0.0, 0.0), -2.0, -2.0);
        NSRect A3Circle = NSInsetRect(NSMakeRect(A3.x, A3.y, 0.0, 0.0), -2.0, -2.0);
        NSBezierPath *A2Path = [NSBezierPath bezierPathWithOvalInRect:A2Circle];
        NSBezierPath *A3Path = [NSBezierPath bezierPathWithOvalInRect:A3Circle];
        [A2Path fill];
        [A3Path fill];
    
        // start and end point
        NSPoint A1 = [transform transformPoint:[points[i-1] pointValue]];
        NSPoint A4 = [transform transformPoint:curvePoints[2]];
        
        // control lines
        NSBezierPath *controlLines = [NSBezierPath bezierPath];
        [controlLines moveToPoint:A1];
        [controlLines lineToPoint:A2];
        [controlLines moveToPoint:A3];
        [controlLines lineToPoint:A4];
        [controlLines stroke];
    }
    
    // draw the points
    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] setFill];
    for (NSValue *value in points)
    {
        NSPoint A = [transform transformPoint:value.pointValue];
        NSRect ACircle = NSInsetRect(NSMakeRect(A.x, A.y, 0.0, 0.0), -5.0, -5.0);
        NSBezierPath *APath = [NSBezierPath bezierPathWithOvalInRect:ACircle];
        [APath fill];
    }

    // draw the curve on top
    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] setStroke];
    [[transform transformBezierPath:smouz] stroke];
}

@end
