//
//  Node.m
//  Back to Ewe
//
//  Created by Matthew Pohlmann on 3/31/14.
//  Copyright 2014 Silly Landmine Studios. All rights reserved.
//

#import "Node.h"
#import "GameplayScene.h"

@implementation Node

@synthesize radius = m_Radius;

- (instancetype) init {
    self = [super init];
    if (self) {
        CGSize winSize = [[CCDirector sharedDirector] viewSize];
        self.position = ccp(winSize.width / 2, winSize.height / 2);
        m_Radius = 20;
        m_BeingRemoved = NO;
        [self drawDot:ccp(0, 0) radius:m_Radius color:[CCColor redColor]];
        
        CCPhysicsBody* physics = [CCPhysicsBody bodyWithCircleOfRadius:m_Radius andCenter:self.anchorPointInPoints];
        physics.type = CCPhysicsBodyTypeStatic;
        physics.collisionCategories = @[@"node"];
        physics.collisionMask = @[@"sheep"];
        physics.collisionType = @"node";
        physics.sensor = YES;
        self.physicsBody = physics;
        
        m_ShrinkTime = 3.0f;
    }
    return self;
}

- (void) update:(CCTime)delta {
    if (m_BeingRemoved) {
        m_ShrinkTime -= delta;
        
        if (m_ShrinkTime <= 0) {
            m_BeingRemoved = NO;
            [m_GameplayScene removeNode:self];
            return;
        }
        
        CGFloat lerpFactor = m_ShrinkTime / 3.0f;
        lerpFactor = clampf(lerpFactor, 0, 1);
        self.scale = 1 * lerpFactor + 0.2f * (1 - lerpFactor);
    }
}

- (void) setGameplayScene:(GameplayScene*)g {
    NSAssert(g != nil, @"Argument must be non-nil");
    
    m_GameplayScene = g;
}

- (void) shrinkAndRemove {
    if (!m_BeingRemoved) {
        m_BeingRemoved = YES;
    }
}

- (CGRect) rect {
    return CGRectMake(self.position.x - self.contentSize.width * self.anchorPoint.x,
                      self.position.y - self.contentSize.height * self.anchorPoint.y,
                      self.contentSize.width,
                      self.contentSize.height);
}

- (bool) isPointInNode:(CGPoint)point {
    CGFloat distanceSqr = ccpDistanceSQ(point, self.position);
    CGFloat radiusSqr = m_Radius * m_Radius;
    
    return distanceSqr <= radiusSqr;
}

@end
