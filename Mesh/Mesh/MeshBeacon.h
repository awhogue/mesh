//
//  MeshBeacon.h
//  Mesh
//
//  Created by ahogue on 11/8/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

@interface MeshBeacon : NSObject

@property (nonatomic, strong) NSNumber* major;
@property (nonatomic, strong) NSNumber* minor;
@property (nonatomic, strong) NSNumber* accuracy;

-(MeshBeacon*)initFromCLBeacon:(CLBeacon*)beacon;
-(MeshBeacon*)initFromData:(NSNumber*)major withMinor:(NSNumber*)minor;

@end
