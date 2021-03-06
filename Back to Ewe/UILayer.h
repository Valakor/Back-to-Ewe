//
//  UILayer.h
//  Back to Ewe
//
//  Created by Matthew Pohlmann on 3/31/14.
//  Copyright 2014 Silly Landmine Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCButton.h"
#import "UIWoolMeter.h"
#import "HighScoresScene.h"
#import "UIHealthMeter.h"

@class GameplayScene;

@interface UILayer : CCNode {
    float m_woolRemaining;
    float m_woolCapacity;
    UIWoolMeter* m_WoolMeter;
    
    float m_healthRemaining;
    float m_healthCapacity;
    UIHealthMeter* m_HealthMeter;
    
    float m_Score;
    CCLabelTTF *m_scoreLabel;
    
    int m_Lives;
    CCLabelTTF* m_livesLabel;
    
    int m_Bombs;
    CCButton* m_bombsButton;
    
    CCLabelTTF* m_GameOverLabel;
    
    CCLabelTTF* m_BossAlertLabel;
    
    CCButton* m_PauseButton;
    CCButton* m_NewGameButton;
    CCButton* m_MainMenuButton;
    CCButton* m_ResumeButton;
    
    GameplayScene* m_gameplayScene;
    
    HighScoresScene* m_HighScoresScene;
}

@property float Wool;
@property float Health;

//----//
- (void) setGameplayScene:(GameplayScene*)g;
- (void) gameOver;
- (void) reset;

- (void) setScoreLabel:(CGFloat)score;
- (void) setLivesLabel:(int)lives;
- (void) setWoolMeter:(float)wool;
- (void) setBombsButtonActive;
- (void) setBombsButtonInactive;
- (void) showBossAlertLabel:(NSString*)vulnerability;;
//----//

@end
