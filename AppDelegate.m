//
// File:		AppDelegate.m
//
// Abstract:	Tells the application to quit once the main window closes
//
// Version:		1.0 - Original release.
//				

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
