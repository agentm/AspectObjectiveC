//
//  TestAOCAspectManager.m
//  AspectObjectiveC
//
//  Created by Tom on 11/03/10.
//  Copyright 2010 . All rights reserved.
//

#import "TestAOCAspectManager.h"
#import "AOCAdvice.h"
#import "AOCAspectManager.h"

static int g_lastArg = 0;
static int g_lastReturnVal = 0;

#pragma mark -
#pragma mark Advice

@interface Add2ToArgBefore : NSObject<AOCAdvice>
@end
@implementation Add2ToArgBefore
-(void) adviceBefore:(NSInvocation*)inv;
{	
	int intArg;
	[inv getArgument:&intArg atIndex:2];
	intArg += 2;
	[inv setArgument:&intArg atIndex:2];
}
@end

@interface Add5ToReturnValueAfter : NSObject<AOCAdvice>
@end
@implementation Add5ToReturnValueAfter
-(void) adviceAfter:(NSInvocation*)inv;
{
	int returnValue;
	[inv getReturnValue:&returnValue];
	returnValue += 5;
	[inv setReturnValue:&returnValue];
}
@end

@interface LogAndReturn40Instead : NSObject<AOCAdvice>
@end
@implementation LogAndReturn40Instead
-(void) adviceInsteadOf:(NSInvocation*)inv;
{
	NSLog(@"Hey, I've got a 40!");
	int myforty = 40;
	[inv setReturnValue:&myforty];
}
@end

#pragma mark -
#pragma mark Tests

@implementation TestAOCAspectManager

-(int) minusTwo:(int)arg;
{
	int returnVal = arg - 2;
	NSLog(@"%@ arg is %i, returning %i", NSStringFromSelector(_cmd), arg, returnVal);
	
	g_lastArg = arg;
	g_lastReturnVal = returnVal;
	return returnVal;
}

-(void) testSharedAspectManagerExists;
{
	STAssertNotNil([AOCAspectManager sharedAspectManager], @"shared aspect manager doesn't exist");
}

-(void) testMultipleAdvice;
{
	STAssertEquals(6, [self minusTwo:8], @"minusTwo: isn't working");
	STAssertEquals(g_lastArg, 8, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 6, @"Return val was wrong");
	
	Add2ToArgBefore* advice1 = [[Add2ToArgBefore new] autorelease];
	Add2ToArgBefore* advice2 = [[Add2ToArgBefore new] autorelease];
	SEL s = @selector(minusTwo:);
	Class cls = [self class];
	
	BOOL didAdd = [[AOCAspectManager sharedAspectManager] addAdvice:advice1
														forSelector:s
															ofClass:cls
															  error:nil];
	
	STAssertTrue(didAdd, @"Adding advice should have succeeded");
	STAssertEquals(8, [self minusTwo:8], @"Advice isn't working");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 8, @"Return val was wrong");
	
	didAdd = [[AOCAspectManager sharedAspectManager] addAdvice:advice2
												   forSelector:s
													   ofClass:cls
														 error:nil];
	STAssertTrue(didAdd, @"Adding advice should have succeeded");
	STAssertEquals(10, [self minusTwo:8], @"Multiple advice isn't working");
	STAssertEquals(g_lastArg, 12, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 10, @"Return val was wrong");
	
	[[AOCAspectManager sharedAspectManager] removeAdvice:advice2
											 forSelector:s
												 ofClass:cls];
	
	STAssertEquals(8, [self minusTwo:8], @"Removal of advice isn't working");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 8, @"Return val was wrong");
	
	//Add aspect that already exists
	didAdd = [[AOCAspectManager sharedAspectManager] addAdvice:advice1
												   forSelector:s
													   ofClass:cls
														 error:nil];
	STAssertFalse(didAdd, @"shouldn't be able to add same advice object twice");
	STAssertEquals(8, [self minusTwo:8], @"The same advice object shouldn't be able to be added twice");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 8, @"Return val was wrong");
}

-(int) minusFive:(int)arg;
{
	int returnVal = arg - 5;
	NSLog(@"%@ arg is %i, returning %i", NSStringFromSelector(_cmd), arg, returnVal);
	
	g_lastArg = arg;
	g_lastReturnVal = returnVal;
	return returnVal;
}

-(void) testAfterAdvice;
{
	STAssertEquals(5, [self minusFive:10], @"minusFive: isn't working");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 5, @"return val was wrong");
	
	Add5ToReturnValueAfter* advice = [[Add5ToReturnValueAfter new] autorelease];
	BOOL didAdd = [[AOCAspectManager sharedAspectManager] addAdvice:advice
														forSelector:@selector(minusFive:)
															ofClass:[self class]
															  error:nil];
	STAssertTrue(didAdd, @"Adding advice should have succeeded");
	
	STAssertEquals(10, [self minusFive:10], @"Advice isn't working");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 5, @"return val was wrong");
}

-(int) addSixteen:(int)arg;
{
	int returnVal = arg + 16;
	NSLog(@"%@ arg is %i, returning %i", NSStringFromSelector(_cmd), arg, returnVal);
	
	g_lastArg = arg;
	g_lastReturnVal = returnVal;
	return returnVal;
}

-(void) testInsteadOfAdvice;
{
	STAssertEquals(26, [self addSixteen:10], @"minusFive: isn't working");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 26, @"return val was wrong");
	
	LogAndReturn40Instead* advice = [[LogAndReturn40Instead new] autorelease];
	BOOL didAdd = [[AOCAspectManager sharedAspectManager] addAdvice:advice
														forSelector:@selector(addSixteen:)
															ofClass:[self class]
															  error:nil];
	STAssertTrue(didAdd, @"Adding advice should have succeeded");
	
	STAssertEquals(40, [self addSixteen:300], @"Advice isn't working");
	STAssertEquals(g_lastArg, 10, @"Arg was wrong");
	STAssertEquals(g_lastReturnVal, 26, @"return val was wrong");
}

@end
