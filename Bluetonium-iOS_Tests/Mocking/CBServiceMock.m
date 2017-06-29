//
//  CBServiceMock.m
//  Bluetonium
//
//  Created by Bas van Kuijck on 29/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

#import "CBServiceMock.h"
#import <OCHamcrest/OCHamcrest.h>
#import <OCMockito/OCMockito.h>

@implementation CBServiceMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _service = mock(CBService.class);
    }
    return self;
}

- (void)setUUID:(CBUUID *)uuid
{
    _UUID = uuid;
    stubProperty(_service, UUID, self.UUID);
}

@end
