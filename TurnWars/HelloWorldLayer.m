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

@end
