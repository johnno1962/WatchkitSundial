//
//  InterfaceController.m
//  Sundial WatchKit Extension
//
//  Created by John Holdsworth on 19/11/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "InterfaceController.h"


@interface InterfaceController() {
    WKInterfaceDevice *dev;
    CGFloat width;
    CGRect rect;
    CGContextRef cg;
    NSCalendar *calendar;
}

@property IBOutlet WKInterfaceGroup *group;
@property IBOutlet WKInterfaceImage *image;

@end

@implementation InterfaceController

- (instancetype)init {
    self = [super init];
    if (self){
        // Initialize variables here.
        // Configure interface objects here.

        dev = [WKInterfaceDevice currentDevice];
        width = dev.screenBounds.size.width;
        if ( width == 136. )
            width -= 7.;
        else
            width -= 4.;
        rect = CGRectMake(0, 0, width*2., width*2.);

        int bitsPerComponent = 8, bytesPerRow = bitsPerComponent/8*4 * rect.size.width;
        cg = CGBitmapContextCreate(calloc( bytesPerRow * rect.size.height, 1 ), rect.size.width, rect.size.height,
                                   bitsPerComponent, bytesPerRow, CGColorSpaceCreateDeviceRGB(),
                                   (CGBitmapInfo)kCGImageAlphaPremultipliedLast);

        // face from http://www.thewoodshop.20m.com/clockfaces.htm
        // pre-scaling image on phone using cg context looks better
        UIImage *face = [UIImage imageNamed:@"clockface_roman02"];
        CGContextDrawImage(cg, CGRectInset(rect, 1, 1), face.CGImage);
        [self.group setBackgroundImage:[self getImage]];

        calendar = [NSCalendar currentCalendar];
    }
    return self;
}

- (UIImage *)getImage {
    CGImageRef image = CGBitmapContextCreateImage(cg);
    UIImage *uiImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    return uiImage;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [self tick];
}

#define XY( _radius, _radians, _spread ) width+sin(_radians)*_radius+_spread, width+cos(_radians)*_radius

- (void)tick {
    NSDate *now = [NSDate date];// dateByAddingTimeInterval:3600*+4.40];
    NSCalendarUnit units = NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
    NSDateComponents *components = [calendar components:units fromDate:now];
    CGFloat radius = width*.8, radians = (components.hour + components.minute/60.)/12.*M_PI*2.;
    CGFloat spread = fmod( radians, M_PI ) < M_PI ? 2. : -2., white[] = {1.,1.,1.,1.};

    CGContextClearRect(cg, rect);

    for ( CGFloat f=0.0 ; f<1.0 ; f+= .1 ) {
        CGFloat shade = .5+f/3., grey[] = {shade,shade,shade,1.};
        CGFloat spread = fmod( radians, M_PI ) < M_PI ? 2. : -2.;

        // hour triangle
        CGContextSetFillColor(cg, grey);
        CGContextMoveToPoint(cg, width, width-width*f/2. );
        //CGContextAddLineToPoint(cg, XY( radius, radians, -spread ));
        CGContextAddLineToPoint(cg, XY( radius, radians, 0*spread ));
        CGContextAddLineToPoint(cg, width, width-width*(f-.1)/2. );
        CGContextFillPath(cg);
    }

    // dial center stroke
    CGContextSetLineWidth(cg, 5.0);
    CGContextSetStrokeColor(cg, white);

    CGContextMoveToPoint(cg, width, width/2.);
    CGContextAddLineToPoint(cg, width, width+width/3.);
    CGContextStrokePath(cg);

    // outer minute marker
    CGFloat minmin = components.minute/60.*M_PI*2., minmax = (components.minute+1)/60.*M_PI*2.;
    CGFloat inner = width*.95, outer = width*.99;

    CGContextSetFillColor(cg, white);
    CGContextMoveToPoint(   cg, XY( inner, minmin, 0. ));
    CGContextAddLineToPoint(cg, XY( outer, minmin, 0. ));
    CGContextAddLineToPoint(cg, XY( outer, minmax, 0. ));
    CGContextAddLineToPoint(cg, XY( inner, minmax, 0. ));
    CGContextFillPath(cg);

    // convert to image data and send to watch
    NSData *data = UIImagePNGRepresentation([self getImage]);
    //NSLog( @"%ld", [data length] );
    [dev addCachedImageWithData:data name:@"hands"];
    [self.image setImageNamed:@"hands"];

    [self performSelector:@selector(tick) withObject:nil afterDelay:60.-components.second];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tick) object:nil];
}

@end



