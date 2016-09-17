//
//  Unit_Cannon.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "Unit_Cannon.h"

@implementation Unit_Cannon

+ (instancetype)nodeWithGame:(HelloWorldLayer *)gameLayer tileDict:(NSDictionary *)tileDict owner:(int)owner {
    return [[self alloc] initWithGame:gameLayer tileDict:tileDict owner:owner];
}

- (instancetype)initWithGame:(HelloWorldLayer *)gameLayer tileDict:(NSDictionary *)tileDict owner:(int)owner {
    self = [super init];
    if (self) {
        self.gameLayer = gameLayer;
        self.owner = owner;
        self.movementRange = 3;
        self.attackRange = 1;
        [self createSprite:tileDict];
        [self.gameLayer addChild:self z:3];
    }
    
    return self;
}

@end
