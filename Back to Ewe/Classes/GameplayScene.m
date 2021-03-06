//
//  GameplayScene.m
//  Back to Ewe
//
//  Created by Matthew Pohlmann on 3/31/14.
//  Copyright Silly Landmine Studios 2014. All rights reserved.
//
// -----------------------------------------------------------------------

#import "GameplayScene.h"
#import "MainMenuScene.h"
#import "Node.h"
#import "WoolString.h"
#import "Grass.h"
#import "Enemy.h"
#import "Powerup.h"
#import "ScreenPhysicsBorders.h"
#import "Projectile.h"
#import "CCActionInterval.h" 
#import "GameplayVariables.h"
#import "AnimatingSprite.h"

// -----------------------------------------------------------------------

// -----------------------------------------------------------------------
#pragma mark - HelloWorldScene
// -----------------------------------------------------------------------

@implementation GameplayScene

// -----------------------------------------------------------------------
#pragma mark - Create & Destroy
// -----------------------------------------------------------------------

+ (GameplayScene *) scene
{
    return [[self alloc] init];
}

// -----------------------------------------------------------------------

- (id) init
{
    // Apple recommend assigning self with supers return value
    self = [super init];
    if (!self) return(nil);
    
    //CCLOG(@"SIZE: (%.f, %.f)", self.contentSize.width, self.contentSize.height);
    
    nodes = [NSMutableArray new];
    nodesToDelete = [NSMutableArray new];
    m_Enemies = [NSMutableArray new];
    m_EnemiesToDelete = [NSMutableArray new];
    grass = [NSMutableArray new];
    m_Powerups = [NSMutableArray new];
    m_PowerupsToDelete = [NSMutableArray new];
    
    // Enable touch handling on scene node
    self.userInteractionEnabled = YES;
    
    //Populate the array of different skins
    m_Backgrounds = [NSMutableArray new];
    [m_Backgrounds addObject:[CCSprite spriteWithImageNamed:@"itp382ewe_bg.png"]];
    
    m_NodeSprites = [NSMutableArray new];
    [m_NodeSprites addObject:@"grass.png"];
    
    m_EnemySprites = [NSMutableArray new];
    [m_EnemySprites addObject:@"enemy_alien.png"];
    
    // Create backgrounds for scrolling
    m_Background1 = [CCSprite spriteWithImageNamed:@"itp382ewe_bg.png"];
    m_Background1.position = ccp(self.contentSize.width / 2, self.contentSize.height/2);
    [m_Background1 setBlendFunc:(ccBlendFunc){GL_ONE,GL_ZERO}];
    m_Background1.zOrder = -2;
    [self addChild:m_Background1];
    
    m_Background2 = [CCSprite spriteWithImageNamed:@"itp382ewe_bg.png"];
    m_Background2.position = ccp(self.contentSize.width / 2, self.contentSize.height/2 + self.contentSize.height);
    [m_Background2 setBlendFunc:(ccBlendFunc){GL_ONE,GL_ZERO}];
    m_Background2.zOrder = -2;
    [self addChild:m_Background2];
    
    // Create physics stuff
    physics = [CCPhysicsNode node];
    physics.collisionDelegate = self;
    physics.debugDraw = NO;
    physics.gravity = ccp(0, -350);
    [self addChild:physics];
    
    ScreenPhysicsBorders* borders = [ScreenPhysicsBorders node];
    [physics addChild:borders];
    
    m_Sheep = [Sheep node];
    [physics addChild:m_Sheep];
    
    nodeGenerator = [NodeGenerator node];
    
    enemyGenerator = [EnemyGenerator node];
    m_CanSpawnEnemies = YES;
    enemySpacing = 333.3f;
    nextEnemySpawnYPos = enemySpacing;
    
    grassGenerator = [GrassGenerator node];
    topGrass = nil;
    
    powerupGenerator = [PowerupGenerator node];
    nextPowerupSpawnYPos = 750.0f;
    powerupSpacing = 500.0f;
    
    m_ProjectileSpacing = 200.0f;
    m_BossEnemySpacing = 300.0f;
    
    bossLevel = NO;
    m_BossLevelTriggerYPos = 10000.0f;
    m_BossLevelSpacing = 10000.0f;
    m_Boss = nil;
    
    m_PlayerLives = 5;
    m_Dead = NO;
    
    //UI Layer
    m_UILayer = [UILayer node];
    [m_UILayer setLivesLabel:m_PlayerLives];
    [m_UILayer setGameplayScene:self];
    [self addChild:m_UILayer];
    
    // Scores
    m_HighScoresLayer = [HighScoresScene node];
    
    // Levels
    //currentLevel = space;
    
    m_Portal = [CCSprite spriteWithImageNamed:@"portal.png"];
    m_Portal.positionType = CCPositionTypeNormalized;
    m_Portal.position = ccp(0.5f, 0.5f);
    m_Portal.visible = false;
    [self addChild:m_Portal];
    
    m_Paused = NO;
    
    m_CanSpawnEnemies = YES;
    m_CanSpawnGrass = YES;
    m_CanSpawnNodes = YES;
    m_CanSpawnPowerup = YES;
    
    // Animation
    arr_explosion = [NSMutableArray arrayWithObjects:@"explode01.png", @"explode02.png", @"explode04.png", @"explode05.png", @"explode06.png", nil];
    
    [self newGame];
    

    
	return self;
     
}

-(void)update:(CCTime)delta{
    
    if (m_Paused) return;
    
    for (Node* node  in nodesToDelete){
        @try{
        [physics removeChild:node];
        }
        @catch (NSException* e) {
                
        }
    }
    [nodes removeObjectsInArray:nodesToDelete];
    [nodesToDelete removeAllObjects];
    
    for (Enemy* enemy  in m_EnemiesToDelete){
        @try{
            [physics removeChild:enemy];
        }
        @catch (NSException* e) {
            
        }
    }
    [m_Enemies removeObjectsInArray:m_EnemiesToDelete];
    [m_EnemiesToDelete removeAllObjects];
    
    for (Powerup* powerup in m_PowerupsToDelete){
        @try{
            [physics removeChild:powerup];
        }
        @catch (NSException* e) {
            
        }
    }
    [m_Powerups removeObjectsInArray:m_PowerupsToDelete];
    [m_PowerupsToDelete removeAllObjects];
    
    if (bossLevel){
        //Translates automatically.
        float translation = delta * 100;
        for(Node* node in nodes){
            node.position = ccp(node.position.x, node.position.y - translation);
            if (node.position.y < 0){
                [nodesToDelete addObject:node];
            }
        }
        //Scrolling
        for(Enemy* enemy in m_Enemies) {
            [enemy setPositionAndCenter:ccp(enemy.position.x, enemy.position.y - translation)];
        }
        for (Grass* _grass in grass) {
            _grass.position =ccp(_grass.position.x, _grass.position.y - translation);
        }
        for (Powerup* _powerup in m_Powerups) {
            _powerup.position = ccp(_powerup.position.x, _powerup.position.y - translation);
        }
        
        m_Background1.position = ccp(m_Background1.position.x, roundf(m_Background1.position.y - translation/3));
        m_Background2.position = ccp(m_Background2.position.x, roundf(m_Background2.position.y - translation/3));
        if (m_Background1.position.y <= -self.contentSize.height/2) {
            m_Background1.position = ccp(m_Background1.position.x, m_Background2.position.y + self.contentSize.height);
            CCSprite* temp = m_Background1;
            m_Background1 = m_Background2;
            m_Background2 = temp;
        }

        
        m_Sheep.position = ccp (m_Sheep.position.x, m_Sheep.position.y - translation);
        topNode = ccp(topNode.x, topNode.y - translation);
        newNodePoint = ccp(newNodePoint.x, newNodePoint.y - translation);
        
        m_Score += translation;
        [m_UILayer setScoreLabel:m_Score];
        
        if(m_Score >= m_NextProjectileSpawnYPos) {
            [self spawnNewProjectile];
            m_NextProjectileSpawnYPos += m_ProjectileSpacing + arc4random() % (int)m_ProjectileSpacing;
        }
        
        if(m_Score >= m_NextBossEnemySpawnYPos) {
            [self spawnNewEnemy];
            m_NextBossEnemySpawnYPos += m_BossEnemySpacing + arc4random() % (int)m_BossEnemySpacing;
        }
        
        if(m_Boss.Health <= 0) {
            [self endBossLevel];
        }
        
    } else
    if (m_Sheep.position.y > 130 && m_Sheep.physicsBody.velocity.y > 0){
        float translation = delta * m_Sheep.physicsBody.velocity.y;
        
        for(Node* node in nodes){
            node.position = ccp(node.position.x, node.position.y - translation);
            if (node.position.y < 0){
                [nodesToDelete addObject:node];
            }
        }
        
        
        //Scrolling
        for(Enemy* enemy in m_Enemies) {
            [enemy setPositionAndCenter:ccp(enemy.position.x, enemy.position.y - translation)];
        }
        for (Grass* _grass in grass) {
            _grass.position =ccp(_grass.position.x, _grass.position.y - translation);
        }
        for (Powerup* _powerup in m_Powerups) {
            _powerup.position = ccp(_powerup.position.x, _powerup.position.y - translation);
        }
        
        m_Background1.position = ccp(m_Background1.position.x, roundf(m_Background1.position.y - translation/3));
        m_Background2.position = ccp(m_Background2.position.x, roundf(m_Background2.position.y - translation/3));
        if (m_Background1.position.y <= -self.contentSize.height/2) {
            m_Background1.position = ccp(m_Background1.position.x, m_Background2.position.y + self.contentSize.height);
            CCSprite* temp = m_Background1;
            m_Background1 = m_Background2;
            m_Background2 = temp;
        }
        
        for(Powerup* _powerup in m_Powerups) {
            if(_powerup.position. y < -_powerup.radius) {
                [m_PowerupsToDelete addObject:_powerup];
            }
        }
        
        for(Enemy* _enemy in m_Enemies) {
            if(_enemy.position. y < -_enemy.radius) {
                [m_EnemiesToDelete addObject:_enemy];
            }
        }
        
        if(m_Score >= nextPowerupSpawnYPos) {
            [self spawnNewPowerup];
            nextPowerupSpawnYPos += powerupSpacing + arc4random() % (int)powerupSpacing;
        }
        
        if(m_Score >= nextEnemySpawnYPos) {
            [self spawnNewEnemy];
            nextEnemySpawnYPos += enemySpacing + arc4random() % (int)enemySpacing;
        }
        
        m_Sheep.position = ccp (m_Sheep.position.x, m_Sheep.position.y - translation);
        newNodePoint = ccp(newNodePoint.x, newNodePoint.y - translation);
        topNode = ccp(topNode.x, topNode.y - translation);
        //NSLog(@"Scroll position : %f", newNodePoint.y);
    
        m_Score += translation;
        [m_UILayer setScoreLabel:m_Score];
    }
    
    if (m_Sheep.position.y >= topNode.y) {
        //NSLog(@"topNode is : %f", topNode.y);
        if(m_CanSpawnNodes) {
        topNode = [nodeGenerator generatePattern:self];
        }
    }
    
    if (m_Sheep.position.y < 0) {
        [self playerDeath];
        if (m_PlayerLives == 0) {
            [self playerDeath];
        }
        return;
    }
    
    if (topGrass == nil) {
        [self spawnNewGrass];
    } else if (topGrass.position.y < 0) {
        [self removeGrass];
        [self spawnNewGrass];
    }
    
    if(m_Score >= m_BossLevelTriggerYPos && bossLevel == NO) {
        [self setupBossBattle];
    }
}

-(void) setNewNodePoint : (CGPoint) point {
    newNodePoint = point;
}

-(CGPoint) getNewNodePoint{
    return newNodePoint;
}

-(void) spawnNewPattern{
    if(m_CanSpawnNodes) {
        topNode = [nodeGenerator generatePattern:self];
    }
}

-(void)setupBossBattle {
    bossLevel = YES;
    
    if([[GameplayVariables get] CurrentLevel] == space) {
        [m_UILayer showBossAlertLabel:@"PROJECTILES"];
    } else if([[GameplayVariables get] CurrentLevel] == jungle) {
        [m_UILayer showBossAlertLabel:@"SHEEPIES"];
    }
    
    m_BossLevelTriggerYPos = m_Score + m_BossEnemySpacing + arc4random() % (int)m_BossEnemySpacing;
    m_NextProjectileSpawnYPos = m_Score + m_ProjectileSpacing + arc4random() % (int)m_ProjectileSpacing;
    [self scheduleOnce:@selector(showBoss) delay:2.1f];
    
    if(m_Boss == nil) {
        m_Boss = [Boss node];
    }
    
    m_NextProjectileSpawnYPos = m_Score + m_ProjectileSpacing;
    m_NextBossEnemySpawnYPos = m_Score + m_BossEnemySpacing;
}

-(void)showBoss {
    CGSize winSize = [[CCDirector sharedDirector] viewSize];
    m_Boss.position = ccp(winSize.width / 2, winSize.height + m_Boss.Radius);
    [m_Boss runAction:[CCActionMoveTo actionWithDuration:3.0f position:ccp(winSize.width / 2, winSize.height - m_Boss.Radius)]];
    [physics addChild: m_Boss];
}

-(void)endBossLevel {
    [[OALSimpleAudio sharedInstance] playEffect:BOSS_DEATH_SOUND];
    
    AnimatingSprite* exp1 = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp1.position = m_Boss.position;
    [self addChild: exp1];
    
    AnimatingSprite* exp2 = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp2.position = ccp(m_Boss.position.x - self.contentSize.width / 5, m_Boss.position.y);
    [self addChild: exp2];
    
    AnimatingSprite* exp3 = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp3.position = ccp(m_Boss.position.x + self.contentSize.width / 5, m_Boss.position.y);
    [self addChild: exp3];
    
    AnimatingSprite* exp4 = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp4.position = ccp(m_Boss.position.x, m_Boss.position.y - self.contentSize.width / 5);
    [self addChild: exp4];
    
    bossLevel = false;
    [physics removeChild:m_Boss];
    
    [self detonateBomb];
    
    [nodesToDelete addObjectsFromArray:nodes];
    
    topGrass = nil;
    
    [m_PowerupsToDelete addObjectsFromArray:m_Powerups];
    
    [m_Sheep spinIntoCenter];
    
    m_Boss = nil;
    m_BossLevelTriggerYPos = m_Score + m_BossLevelSpacing;
    
    m_NextPowerupSpawnYPos = m_Score + powerupSpacing * 2;
    nextEnemySpawnYPos = m_Score + enemySpacing * 2;
    
    m_CanSpawnEnemies = NO;
    m_CanSpawnGrass = NO;
    m_CanSpawnNodes = NO;
    m_CanSpawnPowerup = NO;
    
    m_Portal.scale = 0.0f;
    m_Portal.zOrder = -1;
    m_Portal.visible = true;
    [m_Portal runAction:[CCActionScaleTo actionWithDuration:3.0f scale:0.5f]];
    
    [self scheduleOnce:@selector(switchToNextLevel) delay:3.1f];
}

-(void)switchToNextLevel {
    m_Portal.visible = NO;
    [[GameplayVariables get] switchCurrentLevel];
    NSString* newBackgroundImages;
    switch([GameplayVariables get].CurrentLevel) {
        case space:
            newBackgroundImages = @"itp382ewe_bg.png";
            break;
        case jungle:
            newBackgroundImages = @"itp382ewe_bg-jungle.png";
            break;
        default:
            newBackgroundImages = @"itp382ewe_bg.png";
            break;
    }
    
    m_CanSpawnEnemies = YES;
    m_CanSpawnGrass = YES;
    m_CanSpawnNodes = YES;
    m_CanSpawnPowerup = YES;
    
    [self removeChild:m_Background1];
     m_Background1 = [CCSprite spriteWithImageNamed:newBackgroundImages];
     m_Background1.position = ccp(self.contentSize.width / 2, self.contentSize.height/2);
     [m_Background1 setBlendFunc:(ccBlendFunc){GL_ONE,GL_ZERO}];
     [self addChild:m_Background1 z:-2];
     [self removeChild:m_Background2];
     m_Background2 = [CCSprite spriteWithImageNamed:newBackgroundImages];
     m_Background2.position = ccp(self.contentSize.width / 2, self.contentSize.height/2 + self.contentSize.height);
     [m_Background2 setBlendFunc:(ccBlendFunc){GL_ONE,GL_ZERO}];
    [self addChild:m_Background2 z:-2];
    
    [self respawnPlayer];
    
    topNode = [nodeGenerator generateFirstPattern:self];
    topNode = [nodeGenerator generatePattern:self];
    
    switch([GameplayVariables get].CurrentLevel) {
        case space:
            [[OALSimpleAudio sharedInstance] playBg:BACKGROUND_MUSIC loop:YES];
            break;
        case jungle:
            [[OALSimpleAudio sharedInstance] playBg:CENTIPEDE loop:YES];
            break;
        default:
            [[OALSimpleAudio sharedInstance] playBg:BACKGROUND_MUSIC loop:YES];
            break;
    }
}

-(void)spawnNewPowerup {
    if(m_CanSpawnPowerup) {
        Powerup* newPowerup = [powerupGenerator spawnPowerup];
        [m_Powerups addObject:newPowerup];
        [physics addChild:newPowerup];
    }
}

-(void)removePowerup:(Powerup*) _powerup {
    if(_powerup != nil) {
        [physics removeChild:_powerup];
        _powerup = nil;
    }
}

-(void)spawnNewProjectile {
    Powerup* newPowerup = [powerupGenerator spawnPowerup];
    [newPowerup setProjectileType];
    [m_Powerups addObject:newPowerup];
    [physics addChild:newPowerup];
}

-(void)spawnNewEnemy {
    if(m_CanSpawnEnemies) {
        Enemy* newEnemy = [enemyGenerator spawnEnemy];
        [m_Enemies addObject: newEnemy];
        [physics addChild:newEnemy];
    }
}

-(void)removeEnemy:(Enemy*) _enemy {
    [m_Enemies removeObject:_enemy];
    [physics removeChild:_enemy];
}

- (void) spawnNewGrass {
    if(m_CanSpawnGrass) {
        topGrass = [grassGenerator spawnNewGrass];
        [grass addObject:topGrass];
        [physics addChild:topGrass];
    }
    
}

- (void) removeGrass{
    [grass removeObject:topGrass];
    [physics removeChild:topGrass];
    topGrass = nil;
}

- (void) detonateBomb {
    if(m_Sheep.NumPuffBombs > 0 && m_Dead != YES) {
        [[OALSimpleAudio sharedInstance] playEffect:BOMB_SOUND];
    }
    m_CanSpawnEnemies = NO;
    [self scheduleOnce:@selector(allowEnemySpawn) delay:5.0f];
    for(Enemy* _enemy in m_Enemies) {
        [m_EnemiesToDelete addObject:_enemy];
        AnimatingSprite* exp = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
        exp.position = _enemy.position;
        [self addChild: exp];
    }
    m_Sheep.NumPuffBombs--;
    if(m_Sheep.NumPuffBombs <= 0) {
        m_Sheep.NumPuffBombs = 0;
        [m_UILayer setBombsButtonInactive];
    }
}

-(void) allowEnemySpawn {
    m_CanSpawnEnemies = YES;
}

-(CGSize) getSize{
    return self.contentSize;
}

-(void) addNode : (Node*) n Position:(CGPoint)point{
    /*if (nodes.count > 10){
        [nodesToDelete addObject:[nodes objectAtIndex:(nodes.count - 1)]];
    }*/
    n.position = point;
    n.rotation = (int)arc4random_uniform(90) - 45;
    [n setGameplayScene:self];
    [nodes addObject:n];
    [physics addChild:n];
}

- (void) removeNode:(Node*)toRemove {
    NSAssert(toRemove != nil, @"Argument must be non-nil");
    
    if (m_Sheep.attachedNode == toRemove) {
        [m_Sheep breakString];
    }
    [nodesToDelete addObject:toRemove];
}

- (void) playerDeath {
    if (!m_Dead) {
        [[OALSimpleAudio sharedInstance] playEffect:SHEEP_DEATH_SOUND];
        
        //NSLog(@"Player died");
        m_PlayerLives--;
        [m_UILayer setLivesLabel:m_PlayerLives];
        m_Dead = YES;
        m_Sheep.visible = NO;
        m_Sheep.physicsBody.velocity = ccp(0,0);
        [m_Sheep resetSprite];
        if (m_Sheep.attachedNode) {
            [m_Sheep breakString];
        }
        
        [self detonateBomb];
        
        [self scheduleOnce:@selector(respawnPlayer) delay:2.5f];
        if (m_PlayerLives == 0) {
            [self gameOver];
        }
    }
}

- (void) respawnPlayer {
    CGSize winSize = [[CCDirector sharedDirector] viewSize];
    m_Sheep.position = ccp(winSize.width/2, winSize.height/3);
    m_Sheep.physicsBody.velocity = ccp(0, 500);
    m_Sheep.visible = YES;
    m_Sheep.CurrentHealth = m_Sheep.MaxHealth;
    m_Sheep.CurrentWool = m_Sheep.MaxWool;
    m_UILayer.Health = m_Sheep.CurrentHealth;
    m_UILayer.Wool = m_Sheep.CurrentWool;
    [m_UILayer setWoolMeter:m_Sheep.CurrentWool/m_Sheep.MaxWool];
    m_Dead = NO;
}

- (void) gameOver {
    //NSLog(@"Game Over");
    [m_HighScoresLayer addScore:(int)m_Score];
    [[OALSimpleAudio sharedInstance] playEffect:GAMEOVER_SOUND];
    [m_UILayer gameOver];
    
}

- (void) resetGame {
    if([[GameplayVariables get] CurrentLevel] != space) {
        [[OALSimpleAudio sharedInstance] playBg:BACKGROUND_MUSIC loop:YES];
    }
    
    m_Portal.visible = NO;
    
    [self unscheduleAllSelectors];
    
    [self pause];
    
    [[OALSimpleAudio sharedInstance] stopAllEffects];
    
    [[GameplayVariables get] switchToLevel:space];
    
    m_Sheep.visible = NO;
    [m_Sheep reset];
    [m_Sheep breakString];
    
    [nodesToDelete addObjectsFromArray:nodes];
    
    for(Grass* g in grass) {
        [physics removeChild:g];
    }
    [grass removeAllObjects];
    
    for(Enemy* e in m_Enemies) {
        [physics removeChild:e];
    }
    [m_Enemies removeAllObjects];
    
    m_CanSpawnEnemies = YES;
    enemySpacing = 333.3f;
    nextEnemySpawnYPos = enemySpacing;
    
    bossLevel = false;
    [physics removeChild:m_Boss];
    m_BossLevelTriggerYPos = m_BossLevelSpacing + arc4random() % ((int)m_BossLevelSpacing / 2);
    m_Boss = nil;
    
    newNodePoint = ccp(0, 0);
    
    topNode = ccp(0, 0);
    
    [m_EnemiesToDelete addObjectsFromArray:m_Enemies];
    
    topGrass = nil;
    
    [m_PowerupsToDelete addObjectsFromArray:m_Powerups];
    
    [self detonateBomb];
    
    m_Score = 0;
    
    m_PlayerLives = 5;
    
    m_Sheep.CurrentWool = m_Sheep.MaxWool;
    [m_UILayer setWool:m_Sheep.CurrentWool];
    
    m_Dead = NO;
    
    m_CanSpawnGrass = YES;
    m_CanSpawnNodes = YES;
    m_CanSpawnPowerup = YES;
    
    NSString* newBackgroundImages = @"itp382ewe_bg.png";
    [self removeChild:m_Background1];
    m_Background1 = [CCSprite spriteWithImageNamed:newBackgroundImages];
    m_Background1.position = ccp(self.contentSize.width / 2, self.contentSize.height/2);
    [m_Background1 setBlendFunc:(ccBlendFunc){GL_ONE,GL_ZERO}];
    [self addChild:m_Background1 z:-2];
    [self removeChild:m_Background2];
    m_Background2 = [CCSprite spriteWithImageNamed:newBackgroundImages];
    m_Background2.position = ccp(self.contentSize.width / 2, self.contentSize.height/2 + self.contentSize.height);
    [m_Background2 setBlendFunc:(ccBlendFunc){GL_ONE,GL_ZERO}];
    [self addChild:m_Background2 z:-2];

    
    [m_UILayer reset];
    
    [self newGame];
}

- (void) newGame {
    [[GameplayVariables get] switchToLevel:space];
    topNode = [nodeGenerator generateFirstPattern:self];
    [self detonateBomb];
    m_Sheep.NumPuffBombs = 0;
    nextPowerupSpawnYPos = powerupSpacing;
    [self spawnNewEnemy];
    [self spawnNewGrass];
    [self respawnPlayer];
    [self resume];
}

- (void) pause {
    self.paused = YES;
    m_Paused = YES;
}

- (void) resume {
    self.paused = NO;
    m_Paused = NO;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair sheep:(Sheep *)_sheep grass:(Grass *)_grass {
    [[OALSimpleAudio sharedInstance] playEffect:GET_GRASS_SOUND];
    
    _sheep.CurrentWool += _grass.RCVAmount;
    if (_sheep.CurrentWool >= _sheep.MaxWool) {
        _sheep.CurrentWool = m_Sheep.MaxWool;
    }
    [self removeGrass];
    [self spawnNewGrass];
    
    m_UILayer.Wool = _sheep.CurrentWool;
    [m_UILayer setWoolMeter:m_Sheep.CurrentWool / m_Sheep.MaxWool];
    
    return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair sheep:(Sheep *)_sheep boss:(Boss* )boss {
    if([[GameplayVariables get] CurrentLevel] == jungle) {
        [[OALSimpleAudio sharedInstance] playEffect:BOSS_HIT_SOUND];
        [boss hitBossWithSheep];
    }
    
    return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair projectile:(Projectile *)_projectile boss:(Boss *)boss {
    if([[GameplayVariables get] CurrentLevel] == space) {
        [[OALSimpleAudio sharedInstance] playEffect:BOSS_HIT_SOUND];
        [boss hitBossWithProjectile];
    }
    AnimatingSprite* exp = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp.position = ccp(_projectile.position.x, _projectile.position.y);
    [self addChild: exp];
    [physics removeChild:_projectile];
    return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair sheep:(Sheep *)_sheep enemy:(Enemy *)enemy
{
    if([_sheep hitEnemy]) {
        [[OALSimpleAudio sharedInstance] playEffect:SHEEP_HIT_SOUND];
        m_UILayer.Health = _sheep.CurrentHealth;
    }
    
    [m_EnemiesToDelete addObject:enemy];
    AnimatingSprite* exp = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp.position = enemy.position;
    [self addChild: exp];
    
    if (_sheep.CurrentHealth <= 0) {
        [self playerDeath];
    }
    
    return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair sheep:(Sheep *)_sheep powerup:(Powerup *)powerup
{
    if(powerup.POWERUPTYPE != projectile) {
        [[OALSimpleAudio sharedInstance] playEffect:POWERUP_SOUND];
    }
    
    [_sheep addPowerup:powerup.POWERUPTYPE];
    
    if(powerup.POWERUPTYPE == puffBomb) {
        _sheep.NumPuffBombs++;
        [m_UILayer setBombsButtonActive];
    } else if(powerup.POWERUPTYPE == health) {
        if(_sheep.CurrentHealth < _sheep.MaxHealth) {
            _sheep.CurrentHealth += 10.0f;
            [m_UILayer setHealth:_sheep.CurrentHealth];
        }
    } else if(powerup.POWERUPTYPE == projectile) {
        [[OALSimpleAudio sharedInstance] playEffect:PROJECTILE_SOUND];
        CGSize winSize = [[CCDirector sharedDirector] viewSize];
        Projectile* newProjectile = [[Projectile node] initWithTarget:ccp(winSize.width/2, winSize.height) atPosition:powerup.position];
        [physics addChild:newProjectile];
    }
    
    [m_PowerupsToDelete addObject:powerup];
    
    return YES;
}

-(BOOL) ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair projectile:(Projectile *)bullet border:(ScreenPhysicsBorders *)screenWall {
    AnimatingSprite* exp = [[AnimatingSprite node] initWithFiles:arr_explosion repeat:NO destroyOnFinish:YES delay:0.1f];
    exp.position = ccp(bullet.position.x, bullet.position.y);
    [self addChild: exp];
    [physics removeChild:bullet];
    return YES;
}

// -----------------------------------------------------------------------

- (void) dealloc
{
    // clean up code goes here
}

// -----------------------------------------------------------------------
#pragma mark - Enter & Exit
// -----------------------------------------------------------------------

- (void) onEnter
{
    // always call super onEnter first
    [super onEnter];
    
    // In pre-v3, touch enable and scheduleUpdate was called here
    // In v3, touch is enabled by setting userInterActionEnabled for the individual nodes
    // Per frame update is automatically enabled, if update is overridden
    
}

// -----------------------------------------------------------------------

- (void) onExit
{
    // always call super onExit last
    [super onExit];
}

// -----------------------------------------------------------------------
#pragma mark - Touch Handler
// -----------------------------------------------------------------------

- (void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (m_Paused) {
        return;
    }
    
    if (m_Dead) {
        return;
    }
    
    // Check if user clicked on a node
    CGPoint touchLoc = [touch locationInNode:self];
    for (Node* n in nodes) {
        if ([n isPointInNode:touchLoc]) {
            if (n != m_Sheep.attachedNode) {
                if ([m_Sheep stringToNode:n]) {
                    [[OALSimpleAudio sharedInstance] playEffect:BOING_SOUND];
                    [n shrinkAndRemove];
                    [m_UILayer setWoolMeter:m_Sheep.CurrentWool / m_Sheep.MaxWool];
                    m_UILayer.Wool = m_Sheep.CurrentWool;
                } else {
                    [[OALSimpleAudio sharedInstance] playEffect:OUT_OF_WOOLF_SOUND];
                }
            }
        }
    }
}

- (void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    if (m_Paused) {
        return;
    }
    
    if (m_Dead) {
        return;
    }
    
    [m_Sheep breakString];
}

@end
