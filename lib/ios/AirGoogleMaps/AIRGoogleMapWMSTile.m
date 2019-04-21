//
//  AIRGoogleMapWMSTile.m
//  AirMaps
//
//  Created by nizam on 10/28/18.
//  Copyright © 2018. All rights reserved.
//

#ifdef HAVE_GOOGLE_MAPS

#import "AIRGoogleMapWMSTile.h"
#if __has_include(<EPSGBox/MXEPSGFactory.h>)
#import <EPSGBox/MXEPSGFactory.h>
#else
#import "MXEPSGFactory.h"
#endif

@implementation AIRGoogleMapWMSTile

-(id) init
{
    self = [super init];
    _opacity = 1;
    return self ;
}

- (void)setZIndex:(int)zIndex
{
    _zIndex = zIndex;
    _tileLayer.zIndex = zIndex;
}
- (void)setTileSize:(NSInteger)tileSize
{
    _tileSize = tileSize;
    if(self.tileLayer) {
        self.tileLayer.tileSize = tileSize;
        [self.tileLayer clearTileCache];
    }
}
- (void)setMinimumZ:(NSInteger)minimumZ
{
    _minimumZ = minimumZ;
    if(self.tileLayer && _minimumZ) {
        [self.tileLayer setMinimumZ: _minimumZ ];
        [self.tileLayer clearTileCache];
    }
}

- (void)setMaximumZ:(NSInteger)maximumZ
{
    _maximumZ = maximumZ;
    if(self.tileLayer && maximumZ) {
        [self.tileLayer setMaximumZ: _maximumZ ];
        [self.tileLayer clearTileCache];
    }
}
- (void)setOpacity:(float)opacity
{
    _opacity = opacity;
    if(self.tileLayer ) {
        [self.tileLayer setOpacity:opacity];
        [self.tileLayer clearTileCache];
    }
}

- (void)setUrlTemplate:(NSString *)urlTemplate
{
    _urlTemplate = urlTemplate;
    WMSTileOverlay *tile = [[WMSTileOverlay alloc] init];
    [tile setTemplate:urlTemplate];
    [tile setEpsgSpec: _epsgSpec];
    [tile setMaximumZ:  _maximumZ];
    [tile setMinimumZ: _minimumZ];
    [tile setOpacity: _opacity];
    [tile setTileSize: _tileSize];
    [tile setZIndex: _zIndex];
    _tileLayer = tile;
}
- (void)setEpsgSpec:(NSString *)epsgSpec
{
    _epsgSpec = epsgSpec;
    if(self.tileLayer) {
        [self.tileLayer setEpsgSpec: _epsgSpec];
        [self.tileLayer clearTileCache];
    }
}
@end

@implementation WMSTileOverlay
-(id) init
{
    self = [super init];
    return self ;
}

-(NSArray *)getBoundBox:(NSInteger)x yAxis:(NSInteger)y zoom:(NSInteger)zoom
{
    id<MXEPSGBoundBoxBuilder> builder = [MXEPSGFactory forSpec:self.epsgSpec];
    return [builder boundBoxForX:x Y:y Zoom:zoom ];
}

- (UIImage *)tileForX:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom
{
    NSInteger maximumZ = self.maximumZ;
    NSInteger minimumZ = self.minimumZ;
    if(maximumZ && (long)zoom > (long)maximumZ) {
        return nil;
    }
    if(minimumZ && (long)zoom < (long)minimumZ) {
        return nil;
    }
    NSArray *bb = [self getBoundBox:x yAxis:y zoom:zoom];
    NSMutableString *url = [self.template mutableCopy];
    [url replaceOccurrencesOfString: @"{minX}" withString:[NSString stringWithFormat:@"%@", bb[0]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{minY}" withString:[NSString stringWithFormat:@"%@", bb[1]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{maxX}" withString:[NSString stringWithFormat:@"%@", bb[2]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{maxY}" withString:[NSString stringWithFormat:@"%@", bb[3]] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{width}" withString:[NSString stringWithFormat:@"%d", (int)self.tileSize] options:0 range:NSMakeRange(0, url.length)];
    [url replaceOccurrencesOfString: @"{height}" withString:[NSString stringWithFormat:@"%d", (int)self.tileSize] options:0 range:NSMakeRange(0, url.length)];
    NSURL *uri =  [NSURL URLWithString:url];
    NSData *data = [NSData dataWithContentsOfURL:uri];
    UIImage *img = [[UIImage alloc] initWithData:data];
    CGSize size = [img size];
    UIGraphicsBeginImageContext(size);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    [img drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 0.0);
    CGContextSetLineWidth(context, 5.0);
    CGContextStrokeRect(context, rect);
    img =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end

#endif
