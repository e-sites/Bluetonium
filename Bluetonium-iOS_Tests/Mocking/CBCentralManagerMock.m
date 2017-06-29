//
//  CBCentralManagerMock.m
//  Bluetonium
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

#import "CBCentralManagerMock.h"
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@implementation CBCentralManagerMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _centralManager = mock(CBCentralManager.class);
    }
    return self;
}

- (void)setState:(CBManagerState)state
{
    _state = state;
    stubProperty(_centralManager, state, @(self.state));
}

@end
