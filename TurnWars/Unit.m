//
//  Unit.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "Unit.h"
#import "Unit_Soldier.h"

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
    // Was a unit belonging to the non-active player touched? If yes, do not handle the touch
    if (([self.gameLayer.p1Units containsObject:self] && self.gameLayer.playerTurn == 2) || ([self.gameLayer.p2Units containsObject:self] && self.gameLayer.playerTurn == 1))
        return NO;
    
    // If the action menu is showing, do not handle any touches on unit
    if (self.gameLayer.actionsMenu)
        return NO;
    // If the current unit is the selected unit, do not handle any touches
    if (self.gameLayer.selectedUnit == self)
        return NO;
    // If this unit has moved already, do not handle any touches
    if (self.movedThisTurn)
        return NO;
    
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
    [self unMarkPossibleAttack];
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
    } else if (action == kACTION_ATTACK) {
        [self.gameLayer checkAttackTile:startTileData unitOwner:self.owner];
    }

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
            } else if (action == kACTION_ATTACK) {
                [self.gameLayer checkAttackTile:_neighbourTile unitOwner:self.owner];
            }
            
            // Check how much it costs to move to or attack that tile.
            if (action == kACTION_MOVEMENT) {
                if ([_neighbourTile getGScore]> self.movementRange) {
                    continue;
                }
            } else if(action == kACTION_ATTACK) {
                // is the tile not in range?
                if ([_neighbourTile getGScoreForAttack] > self.attackRange) {
                    // ignore it
                    continue;
                }
            }
            
            [self.spOpenSteps addObject:_neighbourTile];
            [self.spClosedSteps addObject:_neighbourTile];
        }
        i++;
    } while (i < [self.spOpenSteps count]);
    [self.spClosedSteps removeAllObjects];
    [self.spOpenSteps removeAllObjects];
}

-(void)insertOrderedInOpenSteps:(TileData *)tile {
    // Compute the step's F score
    int tileFScore = [tile fScore];
    int count = [self.spOpenSteps count];
    // This will be the index at which we will insert the step
    int i = 0;
    for (; i < count; i++) {
        // If the step's F score is lower or equals to the step at index i
        if (tileFScore <= [[self.spOpenSteps objectAtIndex:i] fScore]) {
            // Then you found the index at which you have to insert the new step
            // Basically you want the list sorted by F score
            break;
        }
    }
    // Insert the new step at the determined index to preserve the F score ordering
    [self.spOpenSteps insertObject:tile atIndex:i];
}

-(int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord {
    // Here you use the Manhattan method, which calculates the total number of steps moved horizontally and vertically to reach the
    // final desired step from the current step, ignoring any obstacles that may be in the way
    return abs(toCoord.x - fromCoord.x) + abs(toCoord.y - fromCoord.y);
}

-(int)costToMoveFromTile:(TileData *)fromTile toAdjacentTile:(TileData *)toTile {
    // Because you can't move diagonally and because terrain is just walkable or unwalkable the cost is always the same.
    // But it has to be different if you can move diagonally and/or if there are swamps, hills, etc...
    return 1;
}

-(void)constructPathAndStartAnimationFromStep:(TileData *)tile {
    [self.movementPath removeAllObjects];
    // Repeat until there are no more parents
    do {
        // Don't add the last step which is the start position (remember you go backward, so the last one is the origin position ;-)
        if (tile.parentTile != nil) {
            // Always insert at index 0 to reverse the path
            [self.movementPath insertObject:tile atIndex:0];
        }
        // Go backward
        tile = tile.parentTile;
    } while (tile != nil);
    [self popStepAndAnimate];
}

-(void)popStepAndAnimate {    
    // 1 - Check if the unit is done moving
    if ([self.movementPath count] == 0) {
        // 1.1 - Mark the unit as not moving
        self.moving = NO;
        [self unMarkPossibleMovement];
        // 1.2 - Mark the tiles that can be attacked
        [self markPossibleAction:kACTION_ATTACK];
        // 1.3 - Check for enemies in range
        BOOL enemiesAreInRange = NO;
        for (TileData *td in self.gameLayer.tileDataArray) {
            if (td.selectedForAttack) {
                enemiesAreInRange = YES;
                break;
            }
        }
        // 1.4 - Show the menu and enable the Attack option if there are enemies in range
        [self.gameLayer showActionsMenu:self canAttack:enemiesAreInRange];
        return;
    }
    
    // Get the next step to move toward
    TileData *s = [self.movementPath objectAtIndex:0];
    // Prepare the action and the callback
    id moveAction = [CCMoveTo actionWithDuration:0.4 position:[self.gameLayer positionForTileCoord:s.tilePosition]];
    // set the method itself as the callback
    id moveCallback = [CCCallFunc actionWithTarget:self selector:@selector(popStepAndAnimate)];
    // Remove the step
    [self.movementPath removeObjectAtIndex:0];
    // Play actions
    [self.unitSprite runAction:[CCSequence actions:moveAction, moveCallback, nil]];
}


-(void)doMarkedMovement:(TileData *)targetTileData {
    if (self.moving)
        return;
    self.moving = YES;
    CGPoint startTile = [self.gameLayer tileCoordForPosition:self.unitSprite.position];
    self.tileDataBeforeMovement = [self.gameLayer getTileData:startTile];
    [self insertOrderedInOpenSteps:self.tileDataBeforeMovement];
    do {
        TileData * _currentTile = ((TileData *)[self.spOpenSteps objectAtIndex:0]);
        CGPoint _currentTileCoord = _currentTile.tilePosition;
        [self.spClosedSteps addObject:_currentTile];
        [self.spOpenSteps removeObjectAtIndex:0];
        // If the currentStep is the desired tile coordinate, you are done!
        if (CGPointEqualToPoint(_currentTile.tilePosition, targetTileData.tilePosition)) {
            [self constructPathAndStartAnimationFromStep:_currentTile];
            // Set to nil to release unused memory
            [self.spOpenSteps removeAllObjects];
            // Set to nil to release unused memory
            [self.spClosedSteps removeAllObjects];
            break;
        }
        NSMutableArray * tiles = [self.gameLayer getTilesNextToTile:_currentTileCoord];
        for (NSValue * tileValue in tiles) {
            CGPoint tileCoord = [tileValue CGPointValue];
            TileData * _neighbourTile = [self.gameLayer getTileData:tileCoord];
            if ([self.spClosedSteps containsObject:_neighbourTile]) {
                continue;
            }
            if ([self.gameLayer otherEnemyUnitInTile:_neighbourTile unitOwner:self.owner]) {
                // Ignore it
                continue;
            }
            if (![self canWalkOverTile:_neighbourTile]) {
                // Ignore it
                continue;
            }
            int moveCost = [self costToMoveFromTile:_currentTile toAdjacentTile:_neighbourTile];
            NSUInteger index = [self.spOpenSteps indexOfObject:_neighbourTile];
            if (index == NSNotFound) {
                _neighbourTile.parentTile = nil;
                _neighbourTile.parentTile = _currentTile;
                _neighbourTile.gScore = _currentTile.gScore + moveCost;
                _neighbourTile.hScore = [self computeHScoreFromCoord:_neighbourTile.tilePosition toCoord:targetTileData.tilePosition];
                [self insertOrderedInOpenSteps:_neighbourTile];
            } else {
                // To retrieve the old one (which has its scores already computed ;-)
                _neighbourTile = [self.spOpenSteps objectAtIndex:index];
                // Check to see if the G score for that step is lower if you use the current step to get there
                if ((_currentTile.gScore + moveCost) < _neighbourTile.gScore) {
                    // The G score is equal to the parent G score + the cost to move from the parent to it
                    _neighbourTile.gScore = _currentTile.gScore + moveCost;
                    // Now you can remove it from the list without being afraid that it can't be released
                    [self.spOpenSteps removeObjectAtIndex:index];
                    // Re-insert it with the function, which is preserving the list ordered by F score
                    [self insertOrderedInOpenSteps:_neighbourTile];
                }
            }
        }
    } while ([self.spOpenSteps count]>0);
}

// Stay on the current tile
-(void)doStay {
    // 1 - Remove the context menu since we've taken an action
    [self.gameLayer removeActionsMenu];
    self.movedThisTurn = YES;
    // 2 - Turn the unit tray to indicate that it has moved
    [self.unitSprite setColor:ccGRAY];
    [self.gameLayer unselectUnit];
    // 3 - Check for victory conditions
    if ([self isKindOfClass:[Unit_Soldier class]]) {
        // If this is a Soldier unit and it is standing over an enemy building, the player wins.
        // We'll handle this situation in detail later
    }
}

// Attack another unit
-(void)doAttack {
    // 1 - Remove the context menu since we've taken an action
    [self.gameLayer removeActionsMenu];
    // 2 - Check if any tile has been selected for attack
    for (TileData *td in self.gameLayer.tileDataArray) {
        if (td.selectedForAttack) {
            // 3 - Mark the selected tile as attackable
            [self.gameLayer paintAttackTile:td];
        }
    }
    self.selectingAttack = YES;
}

// Cancel the move for the current unit and go back to previous position
-(void)doCancel {
    // Remove the context menu since we've taken an action
    [self.gameLayer removeActionsMenu];
    // Move back to the previous tile
    self.unitSprite.position = [self.gameLayer positionForTileCoord:self.tileDataBeforeMovement.tilePosition];
    [self.gameLayer unselectUnit];
}

// Activate this unit for play
- (void)startTurn {
    // Mark the unit as not having moved for this turn
    self.movedThisTurn = NO;
    // Mark the unit as not having attacked this turn
    self.attackedThisTurn = NO;
    // Change the unit overlay colour from gray (inactive) to white (active)
    [self.unitSprite setColor:ccWHITE];
}

// Remove attack selection marking from all tiles
- (void)unMarkPossibleAttack {
    for (TileData *td in self.gameLayer.tileDataArray) {
        [self.gameLayer unPaintAttackTile:td];
        td.parentTile = nil;
        td.selectedForAttack = NO;
    }
}

@end
