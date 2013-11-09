//
//  MeshUser.m
//  Mesh
//
//  Created by ahogue on 11/8/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import "MeshUser.h"

@implementation MeshUser

- (NSString*)toString {
    return [NSString stringWithFormat:@"%@: %@,%@", self.name, self.major, self.minor];
}

@end
