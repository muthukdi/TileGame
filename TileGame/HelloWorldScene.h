//
//  HelloWorldLayer.h
//  TileGame
//
//  Created by Dilip Muthukrishnan on 12-06-27.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldHud
@interface HelloWorldHud : CCLayer
{   
    CCLabelTTF *label;
}

- (void)numCollectedChanged:(int)numCollected;

@end



// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
    CCTMXTiledMap *_tileMap;
    CCTMXLayer *_background;
    CCTMXLayer *_foreground;
    CCTMXLayer *_meta;
    CCSprite *_player;
    int _numCollected;
    HelloWorldHud *_hud;
}

@property (nonatomic, retain) CCTMXTiledMap *tileMap;
@property (nonatomic, retain) CCTMXLayer *background;
@property (nonatomic, retain) CCTMXLayer *foreground;
@property (nonatomic, retain) CCSprite *player;
@property (nonatomic, retain) CCTMXLayer *meta;
@property (nonatomic, assign) int numCollected;
@property (nonatomic, retain) HelloWorldHud *hud;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

-(void)setViewpointCenter:(CGPoint) position;

@end
