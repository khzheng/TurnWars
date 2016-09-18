//
//  HelloWorldLayer.h
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//  Copyright __MyCompanyName__ 2016. All rights reserved.
//

#import "cocos2d.h"

@class TileData;
@class Unit;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer

@property (nonatomic, strong) NSMutableArray *p1Units;
@property (nonatomic, strong) NSMutableArray *p2Units;
@property (nonatomic, assign) int playerTurn;
@property (nonatomic, strong) Unit *selectedUnit;
@property (nonatomic, strong) NSMutableArray *tileDataArray;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

#pragma mark - Helper

- (int)spriteScale;
- (int)getTileHeightForRetina;
- (CGPoint)tileCoordForPosition:(CGPoint)position;
- (CGPoint)positionForTileCoord:(CGPoint)position;
- (NSMutableArray *)getTilesNextToTile:(CGPoint)tileCoord;
- (TileData *)getTileData:(CGPoint)tileCoord;
- (Unit *)otherUnitInTile:(TileData *)tile;
- (Unit *)otherEnemyUnitInTile:(TileData *)tile unitOwner:(int)owner;
- (BOOL)paintMovementTile:(TileData *)tData;
- (void)unPaintMovementTile:(TileData *)tileData;
- (void)selectUnit:(Unit *)unit;
- (void)unselectUnit;

@end
