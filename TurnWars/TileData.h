//
//  TileData.h
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "CCNode.h"
#import "HelloWorldLayer.h"

@interface TileData : CCNode

@property (nonatomic, weak) HelloWorldLayer *gameLayer;
@property (nonatomic, readwrite) CGPoint tilePosition;
@property (nonatomic,readwrite) int movementCost;
@property (nonatomic,readwrite) BOOL selectedForAttack;
@property (nonatomic,readwrite) BOOL selectedForMovement;
@property (nonatomic, copy) NSString *tileType;
@property (nonatomic, weak) TileData *parentTile;

+ (instancetype)nodeWithGame:(HelloWorldLayer *)gameLayer movementCost:(int)movementCost position:(CGPoint)position tileType:(NSString *)tileType;
- (instancetype)initWithGame:(HelloWorldLayer *)gameLayer movementCost:(int)movementCost position:(CGPoint)position tileType:(NSString *)tileType;

@end
