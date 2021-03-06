#import "ABI27_0_0AIRMapOverlay.h"

#import <ReactABI27_0_0/ABI27_0_0RCTBridge.h>
#import <ReactABI27_0_0/ABI27_0_0RCTEventDispatcher.h>
#import <ReactABI27_0_0/ABI27_0_0RCTImageLoader.h>
#import <ReactABI27_0_0/ABI27_0_0RCTUtils.h>
#import <ReactABI27_0_0/UIView+ReactABI27_0_0.h>

@interface ABI27_0_0AIRMapOverlay()
@property (nonatomic, strong, readwrite) UIImage *overlayImage;
@end

@implementation ABI27_0_0AIRMapOverlay {
    ABI27_0_0RCTImageLoaderCancellationBlock _reloadImageCancellationBlock;
    CLLocationCoordinate2D _southWest;
    CLLocationCoordinate2D _northEast;
    MKMapRect _mapRect;
}

- (void)setImageSrc:(NSString *)imageSrc
{
    NSLog(@">>> SET IMAGESRC: %@", imageSrc);
    _imageSrc = imageSrc;

    if (_reloadImageCancellationBlock) {
        _reloadImageCancellationBlock();
        _reloadImageCancellationBlock = nil;
    }
    __weak typeof(self) weakSelf = self;
    _reloadImageCancellationBlock = [_bridge.imageLoader loadImageWithURLRequest:[ABI27_0_0RCTConvert NSURLRequest:_imageSrc]
                                                                            size:weakSelf.bounds.size
                                                                           scale:ABI27_0_0RCTScreenScale()
                                                                         clipped:YES
                                                                      resizeMode:ABI27_0_0RCTResizeModeCenter
                                                                   progressBlock:nil
                                                                partialLoadBlock:nil
                                                                 completionBlock:^(NSError *error, UIImage *image) {
                                                                     if (error) {
                                                                         NSLog(@"%@", error);
                                                                     }
                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                         NSLog(@">>> IMAGE: %@", image);
                                                                         weakSelf.overlayImage = image;
                                                                         [weakSelf createOverlayRendererIfPossible];
                                                                         [weakSelf update];
                                                                     });
                                                                 }];
}

- (void)setBoundsRect:(NSArray *)boundsRect {
    _boundsRect = boundsRect;

    _southWest = CLLocationCoordinate2DMake([boundsRect[1][0] doubleValue], [boundsRect[0][1] doubleValue]);
    _northEast = CLLocationCoordinate2DMake([boundsRect[0][0] doubleValue], [boundsRect[1][1] doubleValue]);

    MKMapPoint southWest = MKMapPointForCoordinate(_southWest);
    MKMapPoint northEast = MKMapPointForCoordinate(_northEast);

    _mapRect = MKMapRectMake(southWest.x, northEast.y, northEast.x - southWest.x, northEast.y - southWest.y);

    [self update];
}

- (void)createOverlayRendererIfPossible
{
    if (MKMapRectIsEmpty(_mapRect) || !self.overlayImage) return;
    __weak typeof(self) weakSelf = self;
    self.renderer = [[ABI27_0_0AIRMapOverlayRenderer alloc] initWithOverlay:weakSelf];
}

- (void)update
{
    if (!_renderer) return;

    if (_map == nil) return;
    [_map removeOverlay:self];
    [_map addOverlay:self];
}


#pragma mark MKOverlay implementation

- (CLLocationCoordinate2D)coordinate
{
    return MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(_mapRect), MKMapRectGetMidY(_mapRect)));
}

- (MKMapRect)boundingMapRect
{
    return _mapRect;
}

- (BOOL)intersectsMapRect:(MKMapRect)mapRect
{
    return MKMapRectIntersectsRect(_mapRect, mapRect);
}

- (BOOL)canReplaceMapContent
{
    return NO;
}

@end
