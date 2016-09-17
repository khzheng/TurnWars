//
//  HelloWorldLayer.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//  Copyright __MyCompanyName__ 2016. All rights reserved.
//

#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "TileData.h"

@interface HelloWorldLayer()

@property (nonatomic, strong) CCTMXTiledMap *tileMap;
@property (nonatomic, strong) CCTMXLayer *bgLayer;
@property (nonatomic, strong) CCTMXLayer *objectLayer;
@property (nonatomic, strong) NSMutableArray *tileDataArray;

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
    self.tileDataArray = [NSMutableArray array];
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

@end
