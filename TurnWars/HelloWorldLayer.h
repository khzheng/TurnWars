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
@property (nonatomic, strong) CCMenu *actionsMenu;
@property (nonatomic, strong) CCSprite *contextMenuBg;
@property (nonatomic, strong) CCMenuItemImage *endTurnButton;
@property (nonatomic, strong) CCLabelBMFont *turnLabel;

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
- (void)showActionsMenu:(Unit *)unit canAttack:(BOOL)canAttack;
- (void)removeActionsMenu;
- (void)addMenu;
- (void)doEndTurn;
- (void)setPlayerTurnLabel;
- (void)showEndTurnTransition;
- (void)beginTurn;
- (void)removeLayer:(CCNode *)n;
- (void)activateUnits:(NSMutableArray *)units;
- (BOOL)checkAttackTile:(TileData *)tData unitOwner:(int)owner;
- (BOOL)paintAttackTile:(TileData *)tData;
- (void)unPaintAttackTiles;
- (void)unPaintAttackTile:(TileData *)tileData;

@end
