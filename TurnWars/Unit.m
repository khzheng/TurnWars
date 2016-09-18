//
//  Unit.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "Unit.h"

#define kACTION_MOVEMENT 0
#define kACTION_ATTACK 1

@implementation Unit

+ (instancetype)nodeWithGame:(HelloWorldLayer *)gameLayer tileDict:(NSDictionary *)tileDict owner:(int)owner {
    // virtual method - implemented in subclasses
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = kStateUngrabbed;
        _hp = 10;
        _spOpenSteps = [NSMutableArray array];
        _spClosedSteps = [NSMutableArray array];
        _movementPath = [NSMutableArray array];
    }
    
    return self;
}

- (void)createSprite:(NSDictionary *)tileDict {
    int x = [tileDict[@"x"] intValue] / [self.gameLayer spriteScale];
    int y = [tileDict[@"y"] intValue] / [self.gameLayer spriteScale];
    int width = [tileDict[@"width"] intValue] / [self.gameLayer spriteScale];
    int height = [tileDict[@"height"] intValue];
    int heightInTiles = height / [self.gameLayer getTileHeightForRetina];
    x += width/2;
    y += (heightInTiles * [self.gameLayer getTileHeightForRetina] / (2 * [self.gameLayer spriteScale]));
    self.unitSprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@_P%d.png", tileDict[@"Type"], self.owner]];
    [self addChild:self.unitSprite];
    self.unitSprite.userData = (__bridge void *)self;
    self.unitSprite.position = ccp(x, y);
    self.hpLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", self.hp] fntFile:@"Font_dark_size12.fnt"];
    [self.unitSprite addChild:self.hpLabel];
    self.hpLabel.position = ccp([self.unitSprite boundingBox].size.width - [self.hpLabel boundingBox].size.width/2, [self.hpLabel boundingBox].size.height/2);
}

- (BOOL)canWalkOverTile:(TileData *)tileData {
    return YES;
}

- (void)onEnter {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    [super onEnter];
}

- (void)onExit {
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
    [super onExit];
}

// Was this unit below the point that was touched?
- (BOOL)containsTouchLocation:(UITouch *)touch {
    if (CGRectContainsPoint([self.unitSprite boundingBox], [self convertTouchToNodeSpaceAR:touch])) {
        return YES;
    }
    return NO;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.state != kStateUngrabbed)
        return NO;
    if (![self containsTouchLocation:touch])
        return NO;
    self.state = kStateGrabbed;
    
    [self.gameLayer unselectUnit];
    [self selectUnit];
    
    return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    self.state = kStateUngrabbed;
}

// Select this unit
-(void)selectUnit {
    [self.gameLayer selectUnit:self];
    // Make the selected unit slightly bigger
    self.unitSprite.scale = 1.2;
    // If the unit was not moved this turn, mark it as possible to move
    if (!self.movedThisTurn) {
        self.selectingMovement = YES;
        [self markPossibleAction:kACTION_MOVEMENT];
    }
}

// Deselect this unit
-(void)unselectUnit {
    // Reset the sprit back to normal size
    self.unitSprite.scale =1;
    self.selectingMovement = NO;
    self.selectingAttack = NO;
    [self unMarkPossibleMovement];
}

// Remove the "possible-to-move" indicator
-(void)unMarkPossibleMovement {
    for (TileData * td in self.gameLayer.tileDataArray) {
        [self.gameLayer unPaintMovementTile:td];
        td.parentTile = nil;
        td.selectedForMovement = NO;
    }
}

// Carry out specified action for this unit
-(void)markPossibleAction:(int)action {
    // Get the tile where the unit is standing
    CGPoint point = [self.gameLayer tileCoordForPosition:self.unitSprite.position];
    TileData *startTileData = [self.gameLayer getTileData:point];
    [self.spOpenSteps addObject:startTileData];
    [self.spClosedSteps addObject:startTileData];
    // If we are selecting movement, paint the tiles
    if (action == kACTION_MOVEMENT) {
        [self.gameLayer paintMovementTile:startTileData];
    }
    // else if(action == kACTION_ATTACK)  // You'll handle attacks later
    int i =0;
    // For each tile in the list, beginning with the start tile
    do {
        TileData * _currentTile = ((TileData *)[self.spOpenSteps objectAtIndex:i]);
        // You get every 4 tiles surrounding the current tile
        NSMutableArray * tiles = [self.gameLayer getTilesNextToTile:_currentTile.tilePosition];
        for (NSValue * tileValue in tiles) {
            TileData * _neighbourTile = [self.gameLayer getTileData:[tileValue CGPointValue]];
            // If you already dealt with it, you ignore it.
            if ([self.spClosedSteps containsObject:_neighbourTile]) {
                // Ignore it
                continue;
            }
            // If there is an enemy on the tile and you are moving, ignore it. You can't move there.
            if (action == kACTION_MOVEMENT && [self.gameLayer otherEnemyUnitInTile:_neighbourTile unitOwner:self.owner]) {
                // Ignore it
                continue;
            }
            // If you are moving and this unit can't walk over that tile type, ignore it.
            if (action == kACTION_MOVEMENT && ![self canWalkOverTile:_neighbourTile]) {
                // Ignore it
                continue;
            }
            _neighbourTile.parentTile = nil;
            _neighbourTile.parentTile = _currentTile;
            // If you can move over there, paint it.
            if (action == kACTION_MOVEMENT) {
                [self.gameLayer paintMovementTile:_neighbourTile];
            }
            // else if(action == kACTION_ATTACK) //You'll handle attacks later
            // Check how much it costs to move to or attack that tile.
            if (action == kACTION_MOVEMENT) {
                if ([_neighbourTile getGScore]> self.movementRange) {
                    continue;
                }
            } else if(action == kACTION_ATTACK) {
                //You'll handle attacks later
            }
            [self.spOpenSteps addObject:_neighbourTile];
            [self.spClosedSteps addObject:_neighbourTile];
        }
        i++;
    } while (i < [self.spOpenSteps count]);
    [self.spClosedSteps removeAllObjects];
    [self.spOpenSteps removeAllObjects];
}

@end
