//
//  NTNetStatusService.h
//  NetStatus
//
//  Created by Derek Knight on 5/06/14.
//  Copyright (c) 2014 Derek Knight. All rights reserved.
//

@class NTNetStatusService;

@protocol NTNetStatusServiceDelegate <NSObject>

- (void) service:(NTNetStatusService *)service
   didGetServers:(NSArray *)servers;

@end

@interface NTNetStatusService : NSObject

+ (void)setDelegate:(id <NTNetStatusServiceDelegate>)delegate;

+ (void)loadData;

@end
