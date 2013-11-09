//
//  MeshUser.h
//  Mesh
//
//  Created by ahogue on 11/8/13.
//  Copyright (c) 2013 ahogue. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MeshUser : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *major;
@property (strong, nonatomic) NSNumber *minor;

-(NSString*)toString;
@end
