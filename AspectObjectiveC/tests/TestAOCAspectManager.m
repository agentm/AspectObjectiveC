//
//  TestAOCAspectManager.m
//  AspectObjectiveC
//
//  Created by Tom on 11/03/10.
//  Copyright 2010 . All rights reserved.
//

#import "TestAOCAspectManager.h"
#import <AspectObjectiveC/AOC.h>


#pragma mark -
#pragma mark Advice

@interface Add2ToArgBefore : NSObject<AOCAdviceProtocol>
@end
@implementation Add2ToArgBefore
-(void) adviceBefore:(id<AOCInvocationProtocol>)inv;
{    
    int intArg;
    [inv getArgument:&intArg atIndex:2];
    intArg += 2;
    [inv setArgument:&intArg atIndex:2];
}
@end

@interface Add5ToReturnValueAfter : NSObject<AOCAdviceProtocol>
@end
@implementation Add5ToReturnValueAfter
-(void) adviceAfter:(id<AOCInvocationProtocol>)inv;
{
    int returnValue;
    [inv getReturnValue:&returnValue];
    returnValue += 5;
    [inv setReturnValue:&returnValue];
}
@end

@interface LogAndReturn40Instead : NSObject<AOCAdviceProtocol>
@end
@implementation LogAndReturn40Instead
-(BOOL) adviceInsteadOf:(id<AOCInvocationProtocol>)inv;
{
    NSLog(@"Hey, I've got a 40!");
    int myforty = 40;
    [inv setReturnValue:&myforty];
    return YES;
}
@end

@interface DidAdviceRunAdvice : NSObject<AOCAdviceProtocol> {
    BOOL didRun;
}
@property(assign) BOOL didRun;
@end
@implementation DidAdviceRunAdvice
@synthesize didRun;
-(BOOL) adviceInsteadOf:(id<AOCInvocationProtocol>)inv;
{
    didRun = YES;
    return YES;
}
@end

#pragma mark -
#pragma mark Tests

@implementation TestAOCAspectManager

-(int) minusTwo:(int)arg;
{
    int returnVal = arg - 2;
    NSLog(@"%@ arg is %i, returning %i", NSStringFromSelector(_cmd), arg, returnVal);
    
    _lastArg = arg;
    _lastReturnVal = returnVal;
    return returnVal;
}

-(void) testSharedAspectManagerExists;
{
    STAssertNotNil([AOCAspectManager defaultAspectManager], @"shared aspect manager doesn't exist");
}

-(void) testMultipleAdvice;
{
    STAssertEquals(6, [self minusTwo:8], @"minusTwo: isn't working");
    STAssertEquals(_lastArg, 8, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 6, @"Return val was wrong");
    
    Add2ToArgBefore* advice1 = [[Add2ToArgBefore new] autorelease];
    Add2ToArgBefore* advice2 = [[Add2ToArgBefore new] autorelease];
    SEL s = @selector(minusTwo:);
    Class cls = [self class];
    
    BOOL didAdd = [[AOCAspectManager defaultAspectManager] installAdvice:advice1
                                                        forSelector:s
                                                            ofClass:cls
                                                              error:nil];
    
    STAssertTrue(didAdd, @"Adding advice should have succeeded");
    STAssertEquals(8, [self minusTwo:8], @"Advice isn't working");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 8, @"Return val was wrong");
    
    didAdd = [[AOCAspectManager defaultAspectManager] installAdvice:advice2
                                                   forSelector:s
                                                       ofClass:cls
                                                         error:nil];
    STAssertTrue(didAdd, @"Adding advice should have succeeded");
    STAssertEquals(10, [self minusTwo:8], @"Multiple advice isn't working");
    STAssertEquals(_lastArg, 12, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 10, @"Return val was wrong");
    
    [[AOCAspectManager defaultAspectManager] uninstallAdvice:advice2
                                             forSelector:s
                                                 ofClass:cls];
    
    STAssertEquals(8, [self minusTwo:8], @"Removal of advice isn't working");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 8, @"Return val was wrong");
    
    //Add aspect that already exists
    didAdd = [[AOCAspectManager defaultAspectManager] installAdvice:advice1
                                                   forSelector:s
                                                       ofClass:cls
                                                         error:nil];
    STAssertFalse(didAdd, @"shouldn't be able to add same advice object twice");
    STAssertEquals(8, [self minusTwo:8], @"The same advice object shouldn't be able to be added twice");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 8, @"Return val was wrong");
}

-(int) minusFive:(int)arg;
{
    int returnVal = arg - 5;
    NSLog(@"%@ arg is %i, returning %i", NSStringFromSelector(_cmd), arg, returnVal);
    
    _lastArg = arg;
    _lastReturnVal = returnVal;
    return returnVal;
}

-(void) testAfterAdvice;
{
    STAssertEquals(5, [self minusFive:10], @"minusFive: isn't working");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 5, @"return val was wrong");
    
    Add5ToReturnValueAfter* advice = [[Add5ToReturnValueAfter new] autorelease];
    BOOL didAdd = [[AOCAspectManager defaultAspectManager] installAdvice:advice
                                                        forSelector:@selector(minusFive:)
                                                            ofClass:[self class]
                                                              error:nil];
    STAssertTrue(didAdd, @"Adding advice should have succeeded");
    
    STAssertEquals(10, [self minusFive:10], @"Advice isn't working");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 5, @"return val was wrong");
}

-(int) addSixteen:(int)arg;
{
    int returnVal = arg + 16;
    NSLog(@"%@ arg is %i, returning %i", NSStringFromSelector(_cmd), arg, returnVal);
    
    _lastArg = arg;
    _lastReturnVal = returnVal;
    return returnVal;
}

-(void) testInsteadOfAdvice;
{
    STAssertEquals(26, [self addSixteen:10], @"minusFive: isn't working");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 26, @"return val was wrong");
    
    LogAndReturn40Instead* advice = [[LogAndReturn40Instead new] autorelease];
    BOOL didAdd = [[AOCAspectManager defaultAspectManager] installAdvice:advice
                                                        forSelector:@selector(addSixteen:)
                                                            ofClass:[self class]
                                                              error:nil];
    STAssertTrue(didAdd, @"Adding advice should have succeeded");
    
    STAssertEquals(40, [self addSixteen:300], @"Advice isn't working");
    STAssertEquals(_lastArg, 10, @"Arg was wrong");
    STAssertEquals(_lastReturnVal, 26, @"return val was wrong");
}

-(int) returnTheArg:(int)arg;
{
    _lastArg = arg;
    _lastReturnVal = arg;
    return arg;
}

-(void) testUninstallAllAdvice;
{
    AOCAspectManager* aspectManager = [[AOCAspectManager new] autorelease];
    DidAdviceRunAdvice* advice = [[DidAdviceRunAdvice new] autorelease];
    advice.didRun = NO;
    
    [aspectManager installAdvice:advice
                     forSelector:@selector(returnTheArg:)
                         ofClass:[self class]
                           error:nil];
    
    STAssertFalse(advice.didRun, @"Shouldn't have run yet");
    [self returnTheArg:0];
    STAssertTrue(advice.didRun, @"advice should have run by now");
    
    advice.didRun = NO;
    [aspectManager uninstallAllAdvice];
    
    STAssertFalse(advice.didRun, @"Shouldn't have run yet");
    [self returnTheArg:1];
    STAssertFalse(advice.didRun, @"Shouldn't have run because of uninstallAllAdvice");
}

-(void) testDealloc;
{
    AOCAspectManager* aspectManager = [AOCAspectManager new];
    DidAdviceRunAdvice* advice = [[DidAdviceRunAdvice new] autorelease];
    advice.didRun = NO;
    
    [aspectManager installAdvice:advice
                     forSelector:@selector(returnTheArg:)
                         ofClass:[self class]
                           error:nil];
    
    STAssertFalse(advice.didRun, @"Shouldn't have run yet");
    [self returnTheArg:0];
    STAssertTrue(advice.didRun, @"advice should have run by now");
    
    advice.didRun = NO;
    [aspectManager release]; aspectManager = nil;
    
    STAssertFalse(advice.didRun, @"Shouldn't have run yet");
    [self returnTheArg:1];
    STAssertFalse(advice.didRun, @"Shouldn't have run because of aspect manager should be deallocated");
}

-(void) testAllocInit;
{
    AOCAspectManager* am = [[AOCAspectManager alloc] init];
    STAssertNotNil(am, @"Couldn't create a new object");
    [am release]; am = nil;
}

@end
