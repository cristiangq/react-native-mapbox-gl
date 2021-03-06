//
//  RCTMGLMapViewManager.m
//  RCTMGL
//
//  Created by Nick Italiano on 8/23/17.
//  Copyright © 2017 Mapbox Inc. All rights reserved.
//

#import <React/RCTUIManager.h>

#import "RCTMGLMapViewManager.h"
#import "RCTMGLMapView.h"
#import "RCTMGLEventTypes.h"
#import "RCTMGLEvent.h"
#import "RCTMGLMapTouchEvent.h"
#import "RCTMGLUtils.h"
#import "CameraStop.h"
#import "CameraUpdateQueue.h"
#import "FilterParser.h"

@interface RCTMGLMapViewManager() <MGLMapViewDelegate>
@end

@implementation RCTMGLMapViewManager

// prevents SDK from crashing and cluttering logs
// since we don't have access to the frame right away
static CGRect const RCT_MAPBOX_MIN_MAP_FRAME = { { 0.0f, 0.0f }, { 64.0f, 64.0f } };

RCT_EXPORT_MODULE(RCTMGLMapView)

- (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (UIView *)view
{
    RCTMGLMapView *mapView = [[RCTMGLMapView alloc] initWithFrame:RCT_MAPBOX_MIN_MAP_FRAME];
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mapView.delegate = self;

    // setup map gesture recongizers
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
    doubleTap.numberOfTapsRequired = 2;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMap:)];
    [tap requireGestureRecognizerToFail:doubleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressMap:)];
    
    // this allows the internal annotation gestures to take precedents over the map tap gesture
    for (int i = 0; i < mapView.gestureRecognizers.count; i++) {
        UIGestureRecognizer *gestuerReconginer = mapView.gestureRecognizers[i];
        
        if ([gestuerReconginer isKindOfClass:[UITapGestureRecognizer class]]) {
            [tap requireGestureRecognizerToFail:gestuerReconginer];
        }
    }
    
    [mapView addGestureRecognizer:doubleTap];
    [mapView addGestureRecognizer:tap];
    [mapView addGestureRecognizer:longPress];
    
    return mapView;
}

#pragma mark - React View Props

RCT_EXPORT_VIEW_PROPERTY(animated, BOOL)
RCT_REMAP_VIEW_PROPERTY(scrollEnabled, reactScrollEnabled, BOOL)
RCT_REMAP_VIEW_PROPERTY(pitchEnabled, reactPitchEnabled, BOOL)
RCT_REMAP_VIEW_PROPERTY(rotateEnabled, reactRotateEnabled, BOOL)
RCT_REMAP_VIEW_PROPERTY(attributionEnabled, reactAttributionEnabled, BOOL)
RCT_REMAP_VIEW_PROPERTY(logoEnabled, reactLogoEnabled, BOOL)
RCT_REMAP_VIEW_PROPERTY(showUserLocation, reactShowUserLocation, BOOL)
RCT_REMAP_VIEW_PROPERTY(compassEnabled, reactCompassEnabled, BOOL)

RCT_REMAP_VIEW_PROPERTY(contentInset, reactContentInset, NSArray)
RCT_REMAP_VIEW_PROPERTY(centerCoordinate, reactCenterCoordinate, NSString)
RCT_REMAP_VIEW_PROPERTY(styleURL, reactStyleURL, NSString)

RCT_REMAP_VIEW_PROPERTY(userTrackingMode, reactUserTrackingMode, int)

RCT_EXPORT_VIEW_PROPERTY(heading, double)
RCT_EXPORT_VIEW_PROPERTY(pitch, double)
RCT_REMAP_VIEW_PROPERTY(zoomLevel, reactZoomLevel, double)
RCT_REMAP_VIEW_PROPERTY(minZoomLevel, reactMinZoomLevel, double)
RCT_REMAP_VIEW_PROPERTY(maxZoomLevel, reactMaxZoomLevel, double)

RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLongPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMapChange, RCTBubblingEventBlock)

#pragma mark - React Methods

RCT_EXPORT_METHOD(getVisibleBounds:(nonnull NSNumber*)reactTag
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *manager, NSDictionary<NSNumber*, UIView*> *viewRegistry) {
        id view = viewRegistry[reactTag];
        
        if (![view isKindOfClass:[RCTMGLMapView class]]) {
            RCTLogError(@"Invalid react tag, could not find RCTMGLMapView");
            return;
        }
        
        RCTMGLMapView *reactMapView = (RCTMGLMapView*)view;
        resolve(@{ @"visibleBounds": [RCTMGLUtils fromCoordinateBounds:reactMapView.visibleCoordinateBounds] });
    }];
}

RCT_EXPORT_METHOD(queryRenderedFeaturesAtPoint:(nonnull NSNumber*)reactTag
                  atPoint:(NSArray<NSNumber*>*)point
                  withFilter:(NSString*)filter
                  withLayerIDs:(NSArray<NSString*>*)layerIDs
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *manager, NSDictionary<NSNumber*, UIView*> *viewRegistry) {
        id view = viewRegistry[reactTag];
        
        if (![view isKindOfClass:[RCTMGLMapView class]]) {
            RCTLogError(@"Invalid react tag, could not find RCTMGLMapView");
            return;
        }
        
        RCTMGLMapView *reactMapView = (RCTMGLMapView*)view;
        NSArray<id<MGLFeature>> *shapes = [reactMapView visibleFeaturesAtPoint:CGPointMake([point[0] floatValue], [point[1] floatValue])
                                                       inStyleLayersWithIdentifiers:[NSSet setWithArray:layerIDs]
                                                       predicate:[FilterParser parse:filter]];
        
        NSMutableArray<NSDictionary*> *features = [[NSMutableArray alloc] init];
        for (int i = 0; i < shapes.count; i++) {
            [features addObject:shapes[i].geoJSONDictionary];
        }

        resolve(@{
          @"data": @{ @"type": @"FeatureCollection", @"features": features }
        });
    }];
}

RCT_EXPORT_METHOD(queryRenderedFeaturesInRect:(nonnull NSNumber*)reactTag
                  withBBox:(NSArray<NSNumber*>*)bbox
                  withFilter:(NSString*)filter
                  withLayerIDs:(NSArray<NSString*>*)layerIDs
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *manager, NSDictionary<NSNumber*, UIView*> *viewRegistry) {
        id view = viewRegistry[reactTag];
        
        if (![view isKindOfClass:[RCTMGLMapView class]]) {
            RCTLogError(@"Invalid react tag, could not find RCTMGLMapView");
            return;
        }
        
        RCTMGLMapView *reactMapView = (RCTMGLMapView*)view;
        
        // bbox[top, right, bottom, left]
        CGFloat width = [bbox[1] floatValue] - [bbox[3] floatValue];
        CGFloat height = [bbox[0] floatValue] - [bbox[2] floatValue];
        CGRect rect = CGRectMake([bbox[3] floatValue], [bbox[2] floatValue], width, height);
        
        NSArray<id<MGLFeature>> *shapes = [reactMapView visibleFeaturesInRect:rect
                                                  inStyleLayersWithIdentifiers:[NSSet setWithArray:layerIDs]
                                                                     predicate:[FilterParser parse:filter]];
        
        NSMutableArray<NSDictionary*> *features = [[NSMutableArray alloc] init];
        for (int i = 0; i < shapes.count; i++) {
            [features addObject:shapes[i].geoJSONDictionary];
        }
        
        resolve(@{ @"data": @{ @"type": @"FeatureCollection", @"features": features }});
    }];
}

RCT_EXPORT_METHOD(setCamera:(nonnull NSNumber*)reactTag
                  withConfiguration:(nonnull NSDictionary*)config
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *manager, NSDictionary<NSNumber*, UIView*> *viewRegistry) {
        id view = viewRegistry[reactTag];
        
        if (![view isKindOfClass:[RCTMGLMapView class]]) {
            RCTLogError(@"Invalid react tag, could not find RCTMGLMapView");
            return;
        }
        
        __weak RCTMGLMapView *reactMapView = (RCTMGLMapView*)view;
        [reactMapView.cameraUpdateQueue flush]; // remove any curreny camera updates
        
        if (config[@"stops"]) {
            NSArray *stops = (NSArray<NSDictionary*>*)config[@"stops"];
            
            for (int i = 0; i < stops.count; i++) {
                [reactMapView.cameraUpdateQueue enqueue:[CameraStop fromDictionary:stops[i]]];
            }
        } else {
            [reactMapView.cameraUpdateQueue enqueue:[CameraStop fromDictionary:config]];
        }

        [reactMapView.cameraUpdateQueue execute:reactMapView withCompletionHandler:^{
            resolve(nil);
        }];
    }];
}

#pragma mark - UIGestureRecognizers

- (void)didTapMap:(UITapGestureRecognizer *)recognizer
{
    RCTMGLMapView *mapView = (RCTMGLMapView*)recognizer.view;
    
    if (mapView == nil || mapView.onPress == nil) {
        return;
    }
    
    RCTMGLMapTouchEvent *event = [RCTMGLMapTouchEvent makeTapEvent:mapView withPoint:[recognizer locationInView:mapView]];
    [self fireEvent:event withCallback:mapView.onPress];
}

- (void)didLongPressMap:(UILongPressGestureRecognizer *)recognizer
{
    RCTMGLMapView *mapView = (RCTMGLMapView*)recognizer.view;
    
    if (mapView == nil || mapView.onPress == nil || recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    RCTMGLMapTouchEvent *event = [RCTMGLMapTouchEvent makeLongPressEvent:mapView withPoint:[recognizer locationInView:mapView]];
    [self fireEvent:event withCallback:mapView.onLongPress];
}

#pragma mark - MGLMapViewDelegate

- (MGLAnnotationView *)mapView:(MGLMapView *)mapView viewForAnnotation:(id<MGLAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *rctAnnotation = (RCTMGLPointAnnotation *)annotation;
        return [rctAnnotation getAnnotationView];
    }
    return nil;
}

- (void)mapView:(MGLMapView *)mapView didSelectAnnotation:(nonnull id<MGLAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *rctAnnotation = (RCTMGLPointAnnotation *)annotation;
        
        if (rctAnnotation.onSelected != nil) {
            RCTMGLMapTouchEvent *event = [RCTMGLMapTouchEvent makeAnnotationTapEvent:rctAnnotation];
            rctAnnotation.onSelected([event toJSON]);
        }
    }
}

- (void)mapView:(MGLMapView *)mapView didDeselectAnnotation:(nonnull id<MGLAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *rctAnnotation = (RCTMGLPointAnnotation *)annotation;
        
        if (rctAnnotation.onDeselected != nil) {
            rctAnnotation.onDeselected(nil);
        }
    }
}

- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id<MGLAnnotation>)annotation {
    if ([annotation isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *rctAnnotation = (RCTMGLPointAnnotation *)annotation;
        return rctAnnotation.calloutView != nil;
    }
    return NO;
}

- (UIView<MGLCalloutView> *)mapView:(MGLMapView *)mapView calloutViewForAnnotation:(id<MGLAnnotation>)annotation
{
    if ([annotation isKindOfClass:[RCTMGLPointAnnotation class]]) {
        RCTMGLPointAnnotation *rctAnnotation = (RCTMGLPointAnnotation *)annotation;
        return rctAnnotation.calloutView;
    }
    return nil;
}

- (void)mapView:(MGLMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    NSDictionary *payload = [self _makeRegionPayload:mapView animated:animated];
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_REGION_WILL_CHANGE_EVENT andPayload:payload];
}

- (void)mapViewRegionIsChanging:(MGLMapView *)mapView
{
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_REGION_IS_CHANGING];
}

- (void)mapView:(MGLMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    NSDictionary *payload = [self _makeRegionPayload:mapView animated:animated];
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_REGION_DID_CHANGE andPayload:payload];
}

- (void)mapViewWillStartLoadingMap:(MGLMapView *)mapView
{
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_WILL_START_LOADING_MAP];
}

- (void)mapViewDidFinishLoadingMap:(MGLMapView *)mapView
{
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_DID_FINISH_LOADING_MAP];
}

- (void)mapViewDidFailLoadingMap:(MGLMapView *)mapView withError:(NSError *)error
{
    NSLog(@"Failed loading map %@", error);
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_DID_FAIL_LOADING_MAP];
}

- (void)mapViewWillStartRenderingFrame:(MGLMapView *)mapView
{
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_WILL_START_RENDERING_FRAME];
}

- (void)mapViewDidFinishRenderingFrame:(MGLMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    if (fullyRendered) {
        [self reactMapDidChange:mapView eventType:RCT_MAPBOX_DID_FINISH_RENDERING_FRAME_FULLY];
    } else {
        [self reactMapDidChange:mapView eventType:RCT_MAPBOX_DID_FINSIH_RENDERING_FRAME];
    }
}

- (void)mapViewWillStartRenderingMap:(MGLMapView *)mapView
{
    [self reactMapDidChange:mapView eventType:RCT_MAPBOX_WILL_START_RENDERING_MAP];
}

- (void)mapViewDidFinishRenderingMap:(MGLMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    if (fullyRendered) {
        [self reactMapDidChange:mapView eventType:RCT_MAPBOX_DID_FINISH_RENDERING_MAP_FULLY];
    } else {
        [self reactMapDidChange:mapView eventType:RCT_MAPBOX_DID_FINISH_RENDERING_MAP];
    }
}

- (void)mapView:(MGLMapView *)mapView didFinishLoadingStyle:(MGLStyle *)style
{
    RCTMGLMapView *reactMapView = (RCTMGLMapView*)mapView;
    
    if (reactMapView.sources.count > 0) {
        for (int i = 0; i < reactMapView.sources.count; i++) {
            RCTMGLSource *source = reactMapView.sources[i];
            source.map = reactMapView;
        }
    }
    
    if (reactMapView.light != nil) {
        reactMapView.light.map = reactMapView;
    }
    
    [self reactMapDidChange:reactMapView eventType:RCT_MAPBOX_DID_FINISH_LOADING_STYLE];
}

- (void)reactMapDidChange:(MGLMapView*)mapView eventType:(NSString*)type
{
    [self reactMapDidChange:mapView eventType:type andPayload:nil];
}

- (void)reactMapDidChange:(MGLMapView*)mapView eventType:(NSString*)type andPayload:(NSDictionary*)payload
{
    RCTMGLMapView *reactMapView = (RCTMGLMapView*)mapView;
    RCTMGLEvent *event = [RCTMGLEvent makeEvent:type withPayload:payload];
    [self fireEvent:event withCallback:reactMapView.onMapChange];
}

- (NSDictionary*)_makeRegionPayload:(MGLMapView*)mapView animated:(BOOL)animated
{
    MGLPointFeature *feature = [[MGLPointFeature alloc] init];
    feature.coordinate = mapView.centerCoordinate;
    feature.attributes = @{
                            @"zoomLevel": [NSNumber numberWithDouble:mapView.zoomLevel],
                            @"heading": [NSNumber numberWithDouble:mapView.camera.heading],
                            @"pitch": [NSNumber numberWithDouble:mapView.camera.pitch],
                            @"animated": [NSNumber numberWithBool:animated],
                            @"visibleBounds": [RCTMGLUtils fromCoordinateBounds:mapView.visibleCoordinateBounds]
                         };
    return feature.geoJSONDictionary;
}

@end
