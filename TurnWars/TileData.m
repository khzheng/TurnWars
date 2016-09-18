//
//  TileData.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "TileData.h"

@implementation TileData

+ (instancetype)nodeWithGame:(HelloWorldLayer *)gameLayer movementCost:(int)movementCost position:(CGPoint)position tileType:(NSString *)tileType {
    return [[self alloc] initWithGame:gameLayer movementCost:movementCost position:position tileType:tileType];
}

- (instancetype)initWithGame:(HelloWorldLayer *)gameLayer movementCost:(int)movementCost position:(CGPoint)position tileType:(NSString *)tileType {
    self = [super init];
    if (self) {
        _gameLayer = gameLayer;
        _selectedForMovement = NO;
        _tileType = tileType;
        _movementCost = movementCost;
        _tilePosition = position;
        _parentTile = nil;
    }
    
    return self;
}

-(int)getGScore {
    int parentCost = 0;
    if (self.parentTile) {
        parentCost = [self.parentTile getGScore];
    }
    return self.movementCost + parentCost;
    
}

-(int)getGScoreForAttack {
    int parentCost = 0;
    if(self.parentTile) {
        parentCost = [self.parentTile getGScoreForAttack];
    }
    return 1 + parentCost;
}

-(int)fScore {
    return self.gScore + self.hScore;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@  pos=[%.0f;%.0f]  g=%d  h=%d  f=%d", [super description], self.tilePosition.x, self.tilePosition.y, self.gScore, self.hScore, [self fScore]];
}

@end
