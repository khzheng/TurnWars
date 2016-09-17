//
//  Unit_Helicopter.h
//  TurnWars
//
//  Created by Ken Zheng on 9/17/16.
//
//

#import "Unit.h"

@interface Unit_Helicopter : Unit

- (instancetype)initWithGame:(HelloWorldLayer *)gameLayer tileDict:(NSDictionary *)tileDict owner:(int)owner;

@end
