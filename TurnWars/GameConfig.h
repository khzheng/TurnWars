//
//  GameConfig.h
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#ifndef GameConfig_h
#define GameConfig_h

#define IS_HD ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == YES && [[UIScreen mainScreen] scale] == 2.0f)

#define TILE_HEIGHT 32
#define TILE_HEIGHT_HD 64

typedef enum tagState {
    kStateGrabbed,
    kStateUngrabbed
} touchState;

#endif /* GameConfig_h */
