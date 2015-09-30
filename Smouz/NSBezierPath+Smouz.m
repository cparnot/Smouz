//  Smouz
//  Created by Charles Parnot on 9/30/15.
//  Licensed under the terms of the modified BSD License, as specified in the file 'LICENSE-BSD.txt' included with this distribution


#import "NSBezierPath+Smouz.h"

@implementation NSBezierPath (Smouz)

#define POINT(i) ([points[i] pointValue])

#define EPSILON 0.000001

+ (instancetype)bezierPathForSmoothedFunctionWithPoints:(NSArray *)unsortedPoints tightness:(CGFloat)tightness bounds:(NSRect)bounds
{
    // tightness should be in 1..100 range
    tightness = fmax(1.0, fmin(100.0, tightness));
    
    // bounds should be positive
    BOOL shouldConstrainBounds = bounds.size.width > 0.0 && bounds.size.height > 0.0;
    CGFloat minX = CGRectGetMinX(bounds);
    CGFloat maxX = CGRectGetMaxX(bounds);
    CGFloat minY = CGRectGetMinY(bounds);
    CGFloat maxY = CGRectGetMaxY(bounds);
    
    // enforce bounds
    NSMutableArray *points = [NSMutableArray array];
    if (shouldConstrainBounds)
    {
        for (NSValue *pointValue in unsortedPoints)
        {
            NSPoint A = pointValue.pointValue;
            A.x = fmin(maxX, fmax(minX, A.x));
            A.y = fmin(maxY, fmax(minY, A.y));
            [points addObject:[NSValue valueWithPoint:A]];
        }
    }
    else
    {
        [points setArray:unsortedPoints];
    }
    
    // sort on x
    [points sortUsingComparator:^NSComparisonResult(NSValue *value1, NSValue *value2)
       {
           CGFloat x1 = value1.pointValue.x;
           CGFloat x2 = value2.pointValue.x;
           return x1 < x2 ? NSOrderedAscending : x1 > x2 ? NSOrderedDescending : NSOrderedSame;
       }];
    
    // the path
    NSBezierPath *path = [[self alloc] init];
    NSUInteger max = points.count;
    for (NSUInteger i = 0; i + 1 < max; i++)
    {
        // the bezier curve will start and end at those 2 points
        // skip points that are too close to each other to avoid crashing
        NSPoint A1 = POINT(i);
        NSPoint A4 = POINT(i+1);
        CGFloat deltaX = A4.x - A1.x;
        if (deltaX < EPSILON)
        {
            continue;
        }
        
        // A0 = point before A1
        // A5 = point after  A4
        // if no point, make one up so that A0-A1 or A4-A5 is flat
        BOOL noPointBeforeA1 = i == 0;
        BOOL noPointAfterA4  = i + 2 >= max;
        NSPoint A0 = noPointBeforeA1 ? NSMakePoint(A1.x - 10.0, A1.y) : POINT(i-1);
        NSPoint A5 = noPointAfterA4  ? NSMakePoint(A4.x + 10.0, A4.y) : POINT(i+2);
        
        // now the slopes on each end of the path = average of the slopes of the segment before and after
        NSPoint A0A1 = NSMakePoint(A1.x - A0.x, A1.y - A0.y);
        NSPoint A1A4 = NSMakePoint(A4.x - A1.x, A4.y - A1.y);
        NSPoint A4A5 = NSMakePoint(A5.x - A4.x, A5.y - A4.y);
        CGFloat slope1 = (A0A1.y / A0A1.x + A1A4.y / A1A4.x) / 2.0;
        CGFloat slope4 = (A1A4.y / A1A4.x + A4A5.y / A4A5.x) / 2.0;
        
        // alternative: instead of averaging the slopes, average the tangent vectors; does not look as good
        // NSPoint A0A1 = NSMakePoint(A1.x - A0.x, A1.y - A0.y);
        // CGFloat normA0A1 = sqrtf(A0A1.x * A0A1.x + A0A1.y * A0A1.y);
        // A0A1.x /= normA0A1;
        // A0A1.y /= normA0A1;
        // NSPoint A1A4 = NSMakePoint(A4.x - A1.x, A4.y - A1.y);
        // CGFloat normA1A4 = sqrtf(A1A4.x * A1A4.x + A1A4.y * A1A4.y);
        // A1A4.x /= normA1A4;
        // A1A4.y /= normA1A4;
        // NSPoint A4A5 = NSMakePoint(A5.x - A4.x, A5.y - A4.y);
        // CGFloat normA4A5 = sqrtf(A4A5.x * A4A5.x + A4A5.y * A4A5.y);
        // A4A5.x /= normA4A5;
        // A4A5.y /= normA4A5;
        // NSPoint A0A1A4 = NSMakePoint((A0A1.x + A1A4.x) / 2.0, (A0A1.y + A1A4.y) / 2.0);
        // NSPoint A1A4A5 = NSMakePoint((A1A4.x + A4A5.x) / 2.0, (A1A4.y + A4A5.y) / 2.0);
        // CGFloat slope1 = A0A1A4.y / A0A1A4.x;
        // CGFloat slope4 = A1A4A5.y / A1A4A5.x;
        
        // and finally, the control points A2 and A3, at 1/3 and 2/3 on the x axis
        // note: 3.0 gives continuous second derivative, which makes the curve looks smoother. For thighter curves, use a higher number like 5.0; for looser curves, use a smaller one like 2.5... but it won't look as smooth.
        CGFloat controlDeltaX = deltaX / tightness;
        NSPoint A2 = NSMakePoint(A1.x + controlDeltaX, A1.y + controlDeltaX * slope1);
        NSPoint A3 = NSMakePoint(A4.x - controlDeltaX, A4.y - controlDeltaX * slope4);
        
        // if the control points are outside the drawing space, alternatively choose them so they are right at the edge (y forced to be 0.0 or 100.0)
        // this will break the second derivative continuity, that's the price to pay to stay within bounds
        if (shouldConstrainBounds)
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
        
        if (i == 0)
        {
            [path moveToPoint:A1];
        }
        [path curveToPoint:A4 controlPoint1:A2 controlPoint2:A3];
    }
    
    return path;
}

@end
