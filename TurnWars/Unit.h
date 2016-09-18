//
//  Unit.h
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "CCNode.h"
#import "HelloWorldLayer.h"
#import "TileData.h"
#import "GameConfig.h"

@interface Unit : CCNode

@property (nonatomic, weak) HelloWorldLayer *gameLayer;
@property (nonatomic, strong) CCSprite *unitSprite;
@property (nonatomic, assign) int owner;
@property (nonatomic, assign) BOOL hasRangedWeapon;
@property (nonatomic, assign) BOOL moving;
@property (nonatomic, assign) int movementRange;
@property (nonatomic, assign) int attackRange;
@property (nonatomic, assign) int hp;
@property (nonatomic, strong) TileData *tileDataBeforeMovement;
@property (nonatomic, assign) touchState state;
@property (nonatomic, strong) CCLabelBMFont *hpLabel;
@property (nonatomic, assign) BOOL movedThisTurn;
@property (nonatomic, assign) BOOL attackedThisTurn;
@property (nonatomic, assign) BOOL selectingMovement;
@property (nonatomic, assign) BOOL selectingAttack;
@property (nonatomic, strong) NSMutableArray *spOpenSteps;
@property (nonatomic, strong) NSMutableArray *spClosedSteps;
@property (nonatomic, strong) NSMutableArray *movementPath;

+ (instancetype)nodeWithGame:(HelloWorldLayer *)gameLayer tileDict:(NSDictionary *)tileDict owner:(int)owner;
- (void)createSprite:(NSDictionary *)tileDict;
- (void)selectUnit;
- (void)unselectUnit;
- (void)unMarkPossibleMovement;
- (void)markPossibleAction:(int)action;
- (void)insertOrderedInOpenSteps:(TileData *)tile;
- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord;
- (int)costToMoveFromTile:(TileData *)fromTile toAdjacentTile:(TileData *)toTile;
- (void)constructPathAndStartAnimationFromStep:(TileData *)tile;
- (void)popStepAndAnimate;
- (void)doMarkedMovement:(TileData *)targetTileData;
- (void)startTurn;
- (void)unMarkPossibleAttack;

@end
