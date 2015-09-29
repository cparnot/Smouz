//  Smouz
//  Created by Charles Parnot on 8/10/14.
//  Licensed under the terms of the modified BSD License, as specified in the file 'LICENSE-BSD.txt' included with this distribution


#import "SmouzView.h"

@implementation SmouzView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    self.data = @[
                  @{ @"x" : @(  0.0), @"y" : @(10.0) }.mutableCopy,
                  @{ @"x" : @( 20.0), @"y" : @(20.0) }.mutableCopy,
                  @{ @"x" : @( 40.0), @"y" : @(20.0) }.mutableCopy,
                  @{ @"x" : @( 45.0), @"y" : @( 5.0) }.mutableCopy,
                  @{ @"x" : @( 50.0), @"y" : @(90.0) }.mutableCopy,
                  @{ @"x" : @( 70.0), @"y" : @(50.0) }.mutableCopy,
                  @{ @"x" : @( 72.0), @"y" : @(80.0) }.mutableCopy,
                  @{ @"x" : @( 75.0), @"y" : @(35.0) }.mutableCopy,
                  @{ @"x" : @( 90.0), @"y" : @( 0.0) }.mutableCopy,
                  @{ @"x" : @(100.0), @"y" : @(90.0) }.mutableCopy,
                  ];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)userDefaultsDidChange:(NSNotification *)notification
{
    [self setNeedsDisplay:YES];
}

#define XX(i) ([self.data[i][@"x"] floatValue])
#define YY(i) ([self.data[i][@"y"] floatValue])
#define POINT(i) (NSMakePoint(XX(i), YY(i)))

#define XX1(i) ([(self.data[i][@"x1"] ?: self.data[i][@"x"]) floatValue])
#define YY1(i) ([(self.data[i][@"y1"] ?: self.data[i][@"y"]) floatValue])
#define POINT1(i) (NSMakePoint(XX1(i), YY1(i)))

#define XX2(i) ([(self.data[i][@"x2"] ?: self.data[i][@"x"]) floatValue])
#define YY2(i) ([(self.data[i][@"y2"] ?: self.data[i][@"y"]) floatValue])
#define POINT2(i) (NSMakePoint(XX2(i), YY2(i)))

#define EPSILON 0.000001

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSArray *sortedData = [self.data sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2)
    {
        return [obj1[@"x"] compare:obj2[@"x"]];
    }];
    
    NSBezierPath *path = [[NSBezierPath alloc] init];
    NSUInteger max = sortedData.count;
    for (NSUInteger i = 0; i + 1 < max; i++)
    {
        // the bezier path will start and end at those 2 points
        // skip points that are too close to each other to avoid crashing
        NSPoint A1 = POINT(i);
        NSPoint A4 = POINT(i+1);
        CGFloat deltaX = A4.x - A1.x;
        if (deltaX < EPSILON)
        {
            continue;
        }
        
        // enforce bounds
        A1 = NSMakePoint(A1.x, fminf(100.0, fmaxf(0.0, A1.y)));
        A4 = NSMakePoint(A4.x, fminf(100.0, fmaxf(0.0, A4.y)));

        // A0 = point before A1
        // A5 = point after  A4
        // if no point, make one up so that A0-A1 or A4-A5 is flat
        BOOL noPointBeforeA1 = i == 0;
        BOOL noPointAfterA4  = i + 2 >= max;
        NSPoint A0 = noPointBeforeA1 ? NSMakePoint(A1.x - 10.0, A1.y) : POINT(i-1);
        NSPoint A5 = noPointAfterA4  ? NSMakePoint(A4.x + 10.0, A4.y) : POINT(i+2);
        
        // now the slopes on each end of the path = average of the slopes of the segment before and after
        CGFloat slope1 = ((A1.y - A0.y) / (A1.x - A0.x) + (A4.y - A1.y) / (A4.x - A1.x)) / 2.0;
        CGFloat slope4 = ((A4.y - A1.y) / (A4.x - A1.x) + (A5.y - A4.y) / (A5.x - A4.x)) / 2.0;
        
        // and finally, the control points A2 and A3, at 1/3 and 2/3 on the x axis
        // note: 3.0 gives continuous second derivative, which makes the curve looks smoother. For thighter curves, use a higher number like 5.0; for looser curves, use a smaller one like 2.5... but it won't look as smooth.
        CGFloat tightness =[[NSUserDefaults standardUserDefaults] floatForKey:@"CurveTightness"];
        if (tightness < 0.0001)
        {
            tightness = 3.0;
        }
        CGFloat controlDeltaX = deltaX / tightness;
        NSPoint A2 = NSMakePoint(A1.x + controlDeltaX, A1.y + controlDeltaX * slope1);
        NSPoint A3 = NSMakePoint(A4.x - controlDeltaX, A4.y - controlDeltaX * slope4);

        // if the control points are outside the drawing space, alternatively choose them so they are right at the edge (y forced to be 0.0 or 100.0)
        // this will break the second derivative continuity, that's the price to pay to stay within bounds
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShouldConstrainBounds"])
        {
            if (A2.y < 0.0)
            {
                A2 = NSMakePoint(A1.x - A1.y / slope1, 0.0);
            }
            else if (A2.y > 100.0)
            {
                A2 = NSMakePoint(A1.x + (100 - A1.y) / slope1, 100.0);
            }
            if (A3.y < 0.0)
            {
                A3 = NSMakePoint(A4.x - A4.y / slope4, 0.0);
            }
            else if (A3.y > 100.0)
            {
                A3 = NSMakePoint(A4.x + (100 - A4.y) / slope4, 100.0);
            }
        }
        
        // keep track of the control points so we can also draw them
        // hack alert: we are directly manipulating entries because we know we have mutable dictionaries inside the data array
        self.data[i][@"x1"] = @(A2.x);
        self.data[i][@"y1"] = @(A2.y);
        self.data[i+1][@"x2"] = @(A3.x);
        self.data[i+1][@"y2"] = @(A3.y);
        
        if (i == 0)
        {
            [path moveToPoint:A1];
        }
        [path curveToPoint:A4 controlPoint1:A2 controlPoint2:A3];
    }
    
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
    
    // draw the points and control points
    for (NSUInteger i = 0; i < max; i++)
    {
        NSPoint point = [transform transformPoint:POINT(i)];
        NSRect circle = NSInsetRect(NSMakeRect(point.x, point.y, 0.0, 0.0), -5.0, -5.0);
        NSBezierPath *pointPath = [NSBezierPath bezierPathWithOvalInRect:circle];
        [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] setFill];
        [pointPath fill];

        NSPoint point1 = [transform transformPoint:POINT1(i)];
        NSRect circle1 = NSInsetRect(NSMakeRect(point1.x, point1.y, 0.0, 0.0), -2.0, -2.0);
        NSBezierPath *point1Path = [NSBezierPath bezierPathWithOvalInRect:circle1];
        [[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] setFill];
        [point1Path fill];

        NSPoint point2 = [transform transformPoint:POINT2(i)];
        NSRect circle2 = NSInsetRect(NSMakeRect(point2.x, point2.y, 0.0, 0.0), -2.0, -2.0);
        NSBezierPath *point2Path = [NSBezierPath bezierPathWithOvalInRect:circle2];
        [[NSColor colorWithCalibratedWhite:0.7 alpha:1.0] setFill];
        [point2Path fill];
        
        NSBezierPath *controlLine = [NSBezierPath bezierPath];
        [controlLine moveToPoint:point1];
        [controlLine lineToPoint:point2];
        [[NSColor colorWithCalibratedWhite:0.85 alpha:1.0] setStroke];
        [controlLine stroke];
    }
    
    // draw the smouzed curve
    [[NSColor colorWithCalibratedWhite:0.3 alpha:1.0] setStroke];
    [[transform transformBezierPath:path] stroke];

}

@end
