//
//  NTNetStatusService.m
//  NetStatus
//
//  Created by Derek Knight on 5/06/14.
//  Copyright (c) 2014 Derek Knight. All rights reserved.
//

#import <AFNetworking.h>
#import "NTNetStatusService.h"

@interface NTNetStatusService ()

@property (nonatomic) NSMutableArray *servers;
@property (nonatomic) NSArray *domainList;
@property (nonatomic) NSArray *serverList;

@property (nonatomic, weak) id <NTNetStatusServiceDelegate> delegate;

@end

@implementation NTNetStatusService

+ (instancetype)theInstance
{
    static NTNetStatusService *theInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
                  ^{
                      theInstance = [NTNetStatusService new];
                      theInstance.domainList = @[@"myserver.mydomain.com"
                                                 ];
                      theInstance.serverList = @[
                                                 @[@"machine1", @"192.168.0.1"],
                                                 @[@"machine2", @"192.168.0.2"]
                                                 ];
                      
                      theInstance.servers = [[NSMutableArray alloc]init];
                      for (NSArray *server in theInstance.serverList)
                      {
                          NSMutableDictionary *record = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                         server[0], @"name",
                                                         server[1], @"ip",
                                                         @"", @"state", nil];
                          [theInstance.servers addObject:record];
                      }
                  });
    
    return theInstance;
}

+ (void)setDelegate:(id<NTNetStatusServiceDelegate>)delegate
{
    [NTNetStatusService theInstance].delegate = delegate;
}

+ (void) loadData
{
    [[NTNetStatusService theInstance] loadData];
}

- (void)loadData
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    for (NSMutableDictionary *server in _servers)
    {
        server[@"state"] = @"";
    }
    
    if (_delegate) [_delegate service:self
                        didGetServers:_servers];

    for (NSString *domain in _domainList)
    {
        for (NSMutableDictionary *server in _servers)
        {
            NSString *url = [NSString stringWithFormat:@"http://%@/netstatus/service/ping?ip=%@", domain, server[@"ip"]];
            [manager GET:url
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject)
             {
                 NSLog(@"JSON: %@", responseObject);
                 BOOL running = [[responseObject[0] objectForKey:@"running"]boolValue];
                 server[@"state"] = running ? @"R" : @"N";
                 if (_delegate) [_delegate service:self
                                     didGetServers:_servers];
                 
             }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error)
             {
                 NSLog(@"Error: %@\n%@", error, operation);
             }];
        }
    }
}

@end
