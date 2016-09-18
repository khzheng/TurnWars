//
//  HelloWorldLayer.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//  Copyright __MyCompanyName__ 2016. All rights reserved.
//

#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "GameConfig.h"
#import "Unit.h"
#import "TileData.h"

@interface HelloWorldLayer()

@property (nonatomic, strong) CCTMXTiledMap *tileMap;
@property (nonatomic, strong) CCTMXLayer *bgLayer;
@property (nonatomic, strong) CCTMXLayer *objectLayer;

@end

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isTouchEnabled = YES;
        
        [self createTileMap];
        
        // load units
        self.p1Units = [NSMutableArray array];
        self.p2Units = [NSMutableArray array];
        [self loadUnits:1];
        [self loadUnits:2];
        
        _playerTurn = 1;
        [self addMenu];
    }
    
    return self;
}

- (void)createTileMap {
    // create map
    self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"StageMap.tmx"];
    [self addChild:self.tileMap];
    
    // get bg layer
    self.bgLayer = [self.tileMap layerNamed:@"Background"];
    
    // get info for each tile in bg layer
    self.tileDataArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.tileMap.mapSize.height; i++) {
        for (int j = 0; j < self.tileMap.mapSize.width; j++) {
            int movementCost = 1;
            NSString *tileType = nil;
            int tileGID = [self.bgLayer tileGIDAt:ccp(j, i)];
            if (tileGID) {
                NSDictionary *properties = [self.tileMap propertiesForGID:tileGID];
                if (properties) {
                    movementCost = [properties[@"MovementCost"] intValue];
                    tileType = properties[@"TileType"];
                }
            }
            
            TileData *tileData = [TileData nodeWithGame:self movementCost:movementCost position:ccp(j, i) tileType:tileType];
            [self.tileDataArray addObject:tileData];
        }
    }
}

- (void)loadUnits:(int)player {
    // get layer based on player number
    CCTMXObjectGroup *unitsObjectGroup = [self.tileMap objectGroupNamed:[NSString stringWithFormat:@"Units_P%d", player]];
    NSMutableArray *units = nil;
    if (player == 1)
        units = self.p1Units;
    else if (player == 2)
        units = self.p2Units;
    
    for (NSMutableDictionary *unitDict in [unitsObjectGroup objects]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:unitDict];
        NSString *unitType = dict[@"Type"];
        NSString *className = [NSString stringWithFormat:@"Unit_%@", unitType];
        Class aClass = NSClassFromString(className);
        Unit *unit = [aClass nodeWithGame:self tileDict:dict owner:player];
        [units addObject:unit];
    }
}

#pragma mark - Touch

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:touch.view];
        location = [[CCDirector sharedDirector] convertToGL:location];
        
        TileData *tileData = [self getTileData:[self tileCoordForPosition:location]];
        
        // move unit to tile if possible
        // Why do i check if the other unit in tile is the selected unit?
        if ((tileData.selectedForMovement && ![self otherUnitInTile:tileData]) || ([self otherUnitInTile:tileData] == self.selectedUnit)) {
            [self.selectedUnit doMarkedMovement:tileData];
        }
        
        // handle attacks here
    }
}

#pragma mark - Helper

// Get the scale for a sprite - 1 for normal display, 2 for retina
-(int)spriteScale {
    if (IS_HD)
        return 2;
    else
        return 1;
}

// Get the height for a tile based on the display type (retina or SD)
-(int)getTileHeightForRetina {
    if (IS_HD)
        return TILE_HEIGHT_HD;
    else
        return TILE_HEIGHT;
}

// Return tile coordinates (in rows and columns) for a given position
-(CGPoint)tileCoordForPosition:(CGPoint)position {
    CGSize tileSize = CGSizeMake(self.tileMap.tileSize.width, self.tileMap.tileSize.height);
    if (IS_HD) {
        tileSize = CGSizeMake(self.tileMap.tileSize.width/2, self.tileMap.tileSize.height/2);
    }
    int x = position.x / tileSize.width;
    int y = ((self.tileMap.mapSize.height * tileSize.height) - position.y) / tileSize.height;
    return ccp(x, y);
}

// Return the position for a tile based on its row and column
-(CGPoint)positionForTileCoord:(CGPoint)position {
    CGSize tileSize = CGSizeMake(self.tileMap.tileSize.width, self.tileMap.tileSize.height);
    if (IS_HD) {
        tileSize = CGSizeMake(self.tileMap.tileSize.width/2, self.tileMap.tileSize.height/2);
    }
    int x = position.x * tileSize.width + tileSize.width/2;
    int y = (self.tileMap.mapSize.height - position.y) * tileSize.height - tileSize.height/2;
    return ccp(x, y);
}

// Get the surrounding tiles (above, below, to the left, and right) of a given tile based on its row and column
-(NSMutableArray *)getTilesNextToTile:(CGPoint)tileCoord {
    NSMutableArray * tiles = [NSMutableArray arrayWithCapacity:4];
    if (tileCoord.y+1<self.tileMap.mapSize.height)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x,tileCoord.y+1)]];
    if (tileCoord.x+1<self.tileMap.mapSize.width)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x+1,tileCoord.y)]];
    if (tileCoord.y-1>=0)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x,tileCoord.y-1)]];
    if (tileCoord.x-1>=0)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x-1,tileCoord.y)]];
    return tiles;
}

// Get the TileData for a tile at a given position
-(TileData *)getTileData:(CGPoint)tileCoord {
    for (TileData * td in self.tileDataArray) {
        if (CGPointEqualToPoint(td.tilePosition, tileCoord)) {
            return td;
        }
    }
    return nil;
}

// Check specified tile to see if there's any other unit (from either player) in it already
-(Unit *)otherUnitInTile:(TileData *)tile {
    for (Unit *u in self.p1Units) {
        if (CGPointEqualToPoint([self tileCoordForPosition:u.unitSprite.position], tile.tilePosition))
            return u;
    }
    for (Unit *u in self.p2Units) {
        if (CGPointEqualToPoint([self tileCoordForPosition:u.unitSprite.position], tile.tilePosition))
            return u;
    }
    return nil;
}

// Check specified tile to see if there's an enemy unit in it already
-(Unit *)otherEnemyUnitInTile:(TileData *)tile unitOwner:(int)owner {
    if (owner == 1) {
        for (Unit *u in self.p2Units) {
            if (CGPointEqualToPoint([self tileCoordForPosition:u.unitSprite.position], tile.tilePosition))
                return u;
        }
    } else if (owner == 2) {
        for (Unit *u in self.p1Units) {
            if (CGPointEqualToPoint([self tileCoordForPosition:u.unitSprite.position], tile.tilePosition))
                return u;
        }
    }
    return nil;
}

// Mark the specified tile for movement, if it hasn't been marked already
-(BOOL)paintMovementTile:(TileData *)tData {
    CCSprite *tile = [self.bgLayer tileAt:tData.tilePosition];
    if (!tData.selectedForMovement) {
        [tile setColor:ccBLUE];
        tData.selectedForMovement = YES;
        return NO;
    }
    return YES;
}

// Set the color of a tile back to the default color
-(void)unPaintMovementTile:(TileData *)tileData {
    CCSprite * tile = [self.bgLayer tileAt:tileData.tilePosition];
    [tile setColor:ccWHITE];
}

// Select specified unit
-(void)selectUnit:(Unit *)unit {
    self.selectedUnit = unit;
}

// Deselect the currently selected unit
-(void)unselectUnit {
    if (self.selectedUnit) {
        [self.selectedUnit unselectUnit];
    }
    self.selectedUnit = nil;
}

-(void)showActionsMenu:(Unit *)unit canAttack:(BOOL)canAttack {
    // 1 - Get the window size
    CGSize wins = [[CCDirector sharedDirector] winSize];
    // 2 - Create the menu background
    self.contextMenuBg = [CCSprite spriteWithFile:@"popup_bg.png"];
    [self addChild:self.contextMenuBg z:19];
    // 3 - Create the menu option labels
    CCLabelBMFont * stayLbl = [CCLabelBMFont labelWithString:@"Stay" fntFile:@"Font_dark_size15.fnt"];
    CCMenuItemLabel * stayBtn = [CCMenuItemLabel itemWithLabel:stayLbl target:unit selector:@selector(doStay)];
    CCLabelBMFont * attackLbl = [CCLabelBMFont labelWithString:@"Attack" fntFile:@"Font_dark_size15.fnt"];
    CCMenuItemLabel * attackBtn = [CCMenuItemLabel itemWithLabel:attackLbl target:unit selector:@selector(doAttack)];
    CCLabelBMFont * cancelLbl = [CCLabelBMFont labelWithString:@"Cancel" fntFile:@"Font_dark_size15.fnt"];
    CCMenuItemLabel * cancelBtn = [CCMenuItemLabel itemWithLabel:cancelLbl target:unit selector:@selector(doCancel)];
    // 4 - Create the menu
    self.actionsMenu = [CCMenu menuWithItems:nil];
    // 5 - Add Stay button
    [self.actionsMenu addChild:stayBtn];
    // 6 - Add the Attack button only if the current unit can attack
    if (canAttack) {
        [self.actionsMenu addChild:attackBtn];
    }
    // 7 - Add the Cancel button
    [self.actionsMenu addChild:cancelBtn];
    // 8 - Add the menu to the layer
    [self addChild:self.actionsMenu z:19];
    // 9 - Position menu
    [self.actionsMenu alignItemsVerticallyWithPadding:5];
    if (unit.unitSprite.position.x > wins.width/2) {
        [self.contextMenuBg setPosition:ccp(100,wins.height/2)];
        [self.actionsMenu setPosition:ccp(100,wins.height/2)];
    } else {
        [self.contextMenuBg setPosition:ccp(wins.width-100,wins.height/2)];
        [self.actionsMenu setPosition:ccp(wins.width-100,wins.height/2)];
    }
}

-(void)removeActionsMenu {
    // Remove the menu from the layer and clean up
    [self.contextMenuBg.parent removeChild:self.contextMenuBg cleanup:YES];
    self.contextMenuBg = nil;
    [self.actionsMenu.parent removeChild:self.actionsMenu cleanup:YES];
    self.actionsMenu = nil;
}

// Add the user turn menu
-(void)addMenu {
    // Get window size
    CGSize wins = [[CCDirector sharedDirector] winSize];
    // Set up the menu background and position
    CCSprite * hud = [CCSprite spriteWithFile:@"uiBar.png"];
    [self addChild:hud];
    [hud setPosition:ccp(wins.width/2,wins.height-[hud boundingBox].size.height/2)];
    // Set up the label showing the turn
    self.turnLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Player %d's turn", self.playerTurn] fntFile:@"Font_dark_size15.fnt"];
    [self addChild:self.turnLabel];
    [self.turnLabel setPosition:ccp([self.turnLabel boundingBox].size.width/2 + 5,wins.height-[hud boundingBox].size.height/2)];
    // Set the turn label to display the current turn
    [self setPlayerTurnLabel];
    // Create End Turn button
    self.endTurnButton = [CCMenuItemImage itemFromNormalImage:@"uiBar_button.png" selectedImage:@"uiBar_button.png" target:self selector:@selector(doEndTurn)];
    CCMenu * menu = [CCMenu menuWithItems:self.endTurnButton, nil];
    [self addChild:menu];
    [menu setPosition:ccp(0,0)];
    [self.endTurnButton setPosition:ccp(wins.width - 3 - [self.endTurnButton boundingBox].size.width/2, wins.height - [self.endTurnButton boundingBox].size.height/2 - 3)];
}

// End the turn, passing control to the other player
-(void)doEndTurn {
    // Do not do anything if a unit is selected
    if (self.selectedUnit)
        return;
    // Switch players depending on who's currently selected
    if (self.playerTurn == 1) {
        self.playerTurn = 2;
    } else if (self.playerTurn == 2) {
        self.playerTurn = 1;
    }
    // Do a transition to signify the end of turn
    [self showEndTurnTransition];
    // Set the turn label to display the current turn
    [self setPlayerTurnLabel];
}

// Set the turn label to display the current turn
-(void)setPlayerTurnLabel {
    // Set the label value for the current player
    [self.turnLabel setString:[NSString stringWithFormat:@"Player %d's turn", self.playerTurn]];
    // Change the label colour based on the player
    if (self.playerTurn == 1) {
        [self.turnLabel setColor:ccRED];
    } else if (self.playerTurn == 2) {
        [self.turnLabel setColor:ccBLUE];
    }
}

// Fancy transition to show turn switch/end
-(void)showEndTurnTransition {
    // Create a black layer
    ccColor4B c = {0,0,0,0};
    CCLayerColor *layer = [CCLayerColor layerWithColor:c];
    [self addChild:layer z:20];
    // Add a label showing the player turn to the black layer
    CCLabelBMFont * turnLbl = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Player %d's turn", self.playerTurn] fntFile:@"Font_silver_size17.fnt"];
    [layer addChild:turnLbl];
    [turnLbl setPosition:ccp([CCDirector sharedDirector].winSize.width/2,[CCDirector sharedDirector].winSize.height/2)];
    // Run an action which fades in the black layer, calls the beginTurn method, fades out the black layer, and finally removes it
    [layer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1 opacity:150],[CCCallFunc actionWithTarget:self selector:@selector(beginTurn)],[CCFadeTo actionWithDuration:1 opacity:0],[CCCallFuncN actionWithTarget:self selector:@selector(removeLayer:)], nil]];
}

// Begin the next turn
-(void)beginTurn {
    // Activate the units for the active player
    if (self.playerTurn == 1) {
        [self activateUnits:self.p2Units];
    } else if (self.playerTurn == 2) {
        [self activateUnits:self.p1Units];
    }
}

// Remove the black layer added for the turn change transition
-(void)removeLayer:(CCNode *)n {
    [n.parent removeChild:n cleanup:YES];
}

// Activate all the units in the specified array (called from beginTurn passing the units for the active player)
-(void)activateUnits:(NSMutableArray *)units {
    for (Unit *unit in units) {
        [unit startTurn];
    }
}

// Check the specified tile to see if it can be attacked
-(BOOL)checkAttackTile:(TileData *)tData unitOwner:(int)owner {
    // Is this tile already marked for attack, if so, we don't need to do anything further
    // If not, does the tile contain an enemy unit? If yes, we can attack this tile
    if (!tData.selectedForAttack && [self otherEnemyUnitInTile:tData unitOwner:owner]!= nil) {
        tData.selectedForAttack = YES;
        return NO;
    }
    return YES;
}

// Paint the given tile as one that can be attacked
-(BOOL)paintAttackTile:(TileData *)tData {
    CCSprite * tile = [self.bgLayer tileAt:tData.tilePosition];
    [tile setColor:ccRED];
    return YES;
}

// Remove the attack marking from all tiles
-(void)unPaintAttackTiles {
    for (TileData * td in self.tileDataArray) {
        [self unPaintAttackTile:td];
    }
}

// Remove the attack marking from a specific tile
-(void)unPaintAttackTile:(TileData *)tileData {
    CCSprite * tile = [self.bgLayer tileAt:tileData.tilePosition];
    [tile setColor:ccWHITE];
}

@end
