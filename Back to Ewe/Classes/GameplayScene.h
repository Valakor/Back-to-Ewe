//
//  GameplayScene.h
//  Back to Ewe
//
//  Created by Matthew Pohlmann on 3/31/14.
//  Copyright Silly Landmine Studios 2014. All rights reserved.
//
// -----------------------------------------------------------------------

// Importing cocos2d.h and cocos2d-ui.h, will import anything you need to start using Cocos2D v3
#import "cocos2d.h"
#import "Sheep.h"
#import "UILayer.h"
@class NodeGenerator;
#import "NodeGenerator.h"
#import "EnemyGenerator.h"
#import "GrassGenerator.h"
#import "PowerupGenerator.h"
#import "Boss.h"
#import "HighScoresScene.h"

// -----------------------------------------------------------------------

/**
 *  The main scene
 */
@interface GameplayScene : CCScene <CCPhysicsCollisionDelegate> {
    Sheep* m_Sheep;
    CCPhysicsNode* physics;
    NSMutableArray* nodes;
    NSMutableArray* nodesToDelete;
    NSMutableArray* grass;
    NSMutableArray* m_Enemies;
    NSMutableArray* m_EnemiesToDelete;
    NSMutableArray* m_Powerups;
    NSMutableArray* m_PowerupsToDelete;
    
    CGPoint newNodePoint;
    
    UILayer* m_UILayer;
    HighScoresScene* m_HighScoresLayer;
    
    NodeGenerator* nodeGenerator;
    BOOL m_CanSpawnNodes;
    CGPoint topNode;
    NSMutableArray* m_NodeSprites;
    
    EnemyGenerator* enemyGenerator;
    BOOL m_CanSpawnEnemies;
    float nextEnemySpawnYPos;
    float enemySpacing;
    NSMutableArray* m_EnemySprites;
    
    BOOL m_CanSpawnGrass;
    GrassGenerator* grassGenerator;
    Grass* topGrass;
    
    BOOL m_CanSpawnPowerup;
    PowerupGenerator* powerupGenerator;
    float nextPowerupSpawnYPos;
    float powerupSpacing;
    
    BOOL bossLevel;
    float m_BossLevelTriggerYPos;
    float m_BossLevelSpacing;
    Boss* m_Boss;
    
    float m_NextPowerupSpawnYPos;
    float m_NextProjectileSpawnYPos;
    float m_ProjectileSpacing;
    
    float m_NextBossEnemySpawnYPos;
    float m_BossEnemySpacing;
    
    float m_Score;
    int m_PlayerLives;
    bool m_Dead;
    
    bool m_Paused;
    
    CCSprite* m_Background1;
    CCSprite* m_Background2;
    NSMutableArray* m_Backgrounds;
    
    CCSprite* m_Portal;
    
    //Animation
    NSMutableArray* arr_explosion;
}

// -----------------------------------------------------------------------

+ (GameplayScene *)scene;
- (void) addNode : (Node*) n Position: (CGPoint) point;
- (void) removeNode:(Node*)toRemove;
- (void) removeGrass;
- (CGSize) getSize;
- (void) setNewNodePoint : (CGPoint) point;
- (CGPoint) getNewNodePoint;
- (id)init;
- (void)spawnNewPattern;
- (void)spawnNewEnemy;
- (void) spawnNewGrass;
- (void) detonateBomb;
- (void) playerDeath;
- (void) resetGame;
- (void) respawnPlayer;
- (void) gameOver;
- (void) pause;
- (void) resume;
- (void) switchToNextLevel;

// -----------------------------------------------------------------------
@end