//
//  ViewController.m
//  Sundial
//
//  Created by John Holdsworth on 19/11/2014.
//  Copyright (c) 2014 John Holdsworth. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    CGFloat width;
    CGRect rect;
    CGContextRef cg;
    NSCalendar *calendar;
}

@property IBOutlet UIImageView *group;
@property IBOutlet UIImageView *image;
@property IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    if (self){
        // Initialize variables here.
        // Configure interface objects here.

        width = self.group.frame.size.width;
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
        [self.group setImage:[self getImage]];

        calendar = [NSCalendar currentCalendar];
    }

    CGRect viewFrame = self.view.frame, groupFrame = self.group.frame, labelFrame = self.label.frame;
    groupFrame.origin.x = (viewFrame.size.width - groupFrame.size.width)/2.0;
    groupFrame.origin.y = (viewFrame.size.height - groupFrame.size.height)/2.0;
    self.group.frame = groupFrame;
    self.image.frame = groupFrame;
    labelFrame.origin.x = (viewFrame.size.width - labelFrame.size.width)/2.0;
    labelFrame.origin.y = groupFrame.origin.y + groupFrame.size.height + 10.0;
    self.label.frame = labelFrame;

    [self willActivate];
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
    NSDate *now = [NSDate date];// dateByAddingTimeInterval:3600*+3.40];
    NSCalendarUnit units = NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
    NSDateComponents *components = [calendar components:units fromDate:now];
    CGFloat radius = width*.8, radians = (components.hour + components.minute/60.)/12.*M_PI*2., white[] = {1.,1.,1.,1.};

    CGContextClearRect(cg, rect);

    for ( CGFloat f=0 ; f<1.0 ; f+= .1 ) {
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
    [self.image setImage:[self getImage]];

    [self performSelector:@selector(tick) withObject:nil afterDelay:60.-components.second];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE, MMM d"];
    self.label.text = [dateFormatter stringFromDate:[NSDate date]];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tick) object:nil];
}

@end
