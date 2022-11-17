//
// File:		AppDelegate.h
//
// Abstract:	Tells the application to quit once the main window closes
//
// Version:		1.0 - Original release.
//				

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
{
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication;

@end
