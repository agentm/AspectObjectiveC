
#import "DemoAppDelegate.h"
#import <AspectObjectiveC/AOC.h>


#pragma mark -
#pragma mark DemoAppDelegate

@implementation DemoAppDelegate

@synthesize celciusTextField = _celciusTextField;
@synthesize fahrenheitTextField = _fahrenheitTextField;
@synthesize hijackButton = _hijackButton;

-(IBAction) convertCelciusToFahrenheit:(id)sender;
{
    double celcius = [_celciusTextField doubleValue];
    double fahrenheit = celcius * (9.0/5.0) + 32.0;
    [_fahrenheitTextField setDoubleValue:fahrenheit];
    NSLog(@"%f degrees celcius = %f degrees fahrenheit. sender = %@", celcius, fahrenheit, sender);
}

-(IBAction) hijack:(id)sender;
{
    if(_isHijacked)
        return;
    
    NSError* error = nil;
    BOOL didHijack = [[AOCAspectManager defaultAspectManager] installAdvice:_hijackAdvice
                                                                forSelector:@selector(convertCelciusToFahrenheit:)
                                                                    ofClass:[DemoAppDelegate class]
                                                                      error:&error];
    if(!didHijack){
        [NSApp presentError:error];
        return;
    }
    
    [_hijackButton setTitle:NSLocalizedString(@"Unhijack", nil)];
    _isHijacked = YES;
}

-(IBAction) unhijack:(id)sender;
{
    if(!_isHijacked)
        return;
    
    [[AOCAspectManager defaultAspectManager] uninstallAdvice:_hijackAdvice
                                                 forSelector:@selector(convertCelciusToFahrenheit:)
                                                     ofClass:[DemoAppDelegate class]];
    
    [_hijackButton setTitle:NSLocalizedString(@"Hijack!", nil)];
    _isHijacked = NO;
}

-(IBAction) toggleHijacked:(id)sender;
{
    if(_isHijacked){
        [self unhijack:sender];
    } else {
        [self hijack:sender];
    }
}

#pragma mark NSWindowController

- (void)windowWillClose:(NSNotification *)notification;
{
    [NSApp terminate:self];
}

#pragma mark NSObject

-(id) init;
{
    self = [super init];
    if(self == nil)
        return nil;
    
    _isHijacked = NO;
    _hijackAdvice = [[HijackAdvice alloc] init];
    
    return self;
}

-(void) dealloc;
{
    [self unhijack:self];
    [_celciusTextField release]; _celciusTextField = nil;
    [_fahrenheitTextField release]; _fahrenheitTextField = nil;
    [_hijackButton release]; _hijackButton = nil;
    [_hijackAdvice release]; _hijackAdvice = nil;
    [super dealloc];
}

@end
