//
//  HelloWorldLayer.m
//  TileGame
//
//  Created by Dilip Muthukrishnan on 12-06-27.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldScene.h"
#import "SimpleAudioEngine.h"

// HelloWorldHud implementation
@implementation HelloWorldHud

-(id) init
{
    if ((self = [super init])) {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        label = [CCLabelTTF labelWithString:@"0" dimensions:CGSizeMake(50, 20)
                               alignment:UITextAlignmentRight fontName:@"Verdana-Bold" 
                                fontSize:18.0];
        label.color = ccc3(0,0,0);
        int margin = 10;
        label.position = ccp(winSize.width - (label.contentSize.width/2) 
                             - margin, label.contentSize.height/2 + margin);
        [self addChild:label];
    }
    return self;
}

- (void)numCollectedChanged:(int)numCollected {
    [label setString:[NSString stringWithFormat:@"%d", numCollected]];
}

@end



// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize foreground = _foreground;
@synthesize meta = _meta;
@synthesize player = _player;
@synthesize numCollected = _numCollected;
@synthesize hud = _hud;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
    
    // add label display layer to scene
    HelloWorldHud *hud = [HelloWorldHud node];    
    [scene addChild: hud];
    
    layer.hud = hud;
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"TileMap.caf"];
    if( (self=[super init] )) {
        
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        self.background = [_tileMap layerNamed:@"Background"];
        self.foreground = [_tileMap layerNamed:@"Foreground"];
        self.meta = [_tileMap layerNamed:@"Meta"];
        _meta.visible = NO;
        CCTMXObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objects != nil, @"'Objects' object group not found");
        NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];        
        NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
        int x = [[spawnPoint valueForKey:@"x"] intValue];
        int y = [[spawnPoint valueForKey:@"y"] intValue];
        
        self.player = [CCSprite spriteWithFile:@"Player.png"];
        _player.position = ccp(x, y);
        [self addChild:_player]; 
        
        [self setViewpointCenter:_player.position];
        
        [self addChild:_tileMap z:-1];
        self.isTouchEnabled = YES;
        
    }
    return self;
}

// Convert x,y coordinates to tile coordinates
- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}

// Spwan the player at a specific position on the map
-(void)setViewpointCenter:(CGPoint) position {
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width / 2);
    int y = MAX(position.y, winSize.height / 2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) 
            - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) 
            - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
    
}

// Sets the position of the player
-(void)setPlayerPosition:(CGPoint)position {
	CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = [properties valueForKey:@"Collidable"];
            if (collision && [collision compare:@"True"] == NSOrderedSame) {
                [[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
                return;
            }
            NSString *collectable = [properties valueForKey:@"Collectable"];
            if (collectable && [collectable compare:@"True"] == NSOrderedSame) {
                [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.caf"];
                [_meta removeTileAt:tileCoord];
                [_foreground removeTileAt:tileCoord];
                self.numCollected++;
                [_hud numCollectedChanged:_numCollected];
            }
        }
    }
    _player.position = position;
}

// Calculate new player position based on touch location and reset the view point
-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView: [touch view]];		
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    CGPoint playerPos = _player.position;
    CGPoint diff = ccpSub(touchLocation, playerPos);
    if (abs(diff.x) > abs(diff.y)) {
        if (diff.x > 0) {
            playerPos.x += _tileMap.tileSize.width;
        } else {
            playerPos.x -= _tileMap.tileSize.width; 
        }    
    } else {
        if (diff.y > 0) {
            playerPos.y += _tileMap.tileSize.height;
        } else {
            playerPos.y -= _tileMap.tileSize.height;
        }
    }
    
    if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
        playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
        playerPos.y >= 0 &&
        playerPos.x >= 0 ) 
    {
        [self setPlayerPosition:playerPos];
    }
    [[SimpleAudioEngine sharedEngine] playEffect:@"move.caf"];
    [self setViewpointCenter:_player.position];
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	self.tileMap = nil;
    self.background = nil;
    self.foreground = nil;
    self.meta = nil;
    self.player = nil;
    self.hud = nil;
    
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
