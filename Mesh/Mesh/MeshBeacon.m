//
//  MeshBeacon.m
//  Mesh
//
//  Created by ahogue on 11/8/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import "MeshBeacon.h"

@implementation MeshBeacon

-(MeshBeacon*)initFromCLBeacon:(CLBeacon*)beacon {
    self.major = beacon.major;
    self.minor = beacon.minor;
    return self;
}
-(MeshBeacon*)initFromData:(NSNumber*)major withMinor:(NSNumber*)minor {
    self.major = major;
    self.minor = minor;
    return self;
}


@end
