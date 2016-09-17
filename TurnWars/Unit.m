//
//  Unit.m
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "Unit.h"

@implementation Unit

+ (instancetype)nodeWithGame:(HelloWorldLayer *)gameLayer tileDict:(NSDictionary *)tileDict ownder:(int)owner {
    // virtual method - implemented in subclasses
    return nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = kStateUngrabbed;
        _hp = 10;
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
    return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    self.state = kStateUngrabbed;
}

@end
