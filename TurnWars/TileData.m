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

@end
