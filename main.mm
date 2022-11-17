
#import <Cocoa/Cocoa.h>
#include "main.h"

#include <map>
#include <array>
#include <vector>
#include <string>

int num_vertices = 0;
int num_colours = 0;
float view_ratio = 1;
float rotate[3] = { 0, 0, 0 };
GLfloat zoom_value = 1;
GLfloat dest_zoom = zoom_value;
GLfloat offset_value[2] = { 0, 0 };
GLfloat dest_offset_value[2] = { 0, 0 };
double content_bounds[4] = { 100000000, -100000000, 100000000, -100000000 };
double content_center[2] = { 0, 0 };
void extend_content_bounds(double x, double y) {
  content_bounds[0] = fmin(content_bounds[0], x);
  content_bounds[1] = fmax(content_bounds[1], x);
  content_bounds[2] = fmin(content_bounds[2], y);
  content_bounds[3] = fmax(content_bounds[3], y);
}

@implementation BasicOpenGLView

- (void) drawRect:(NSRect)rect {
  [[self openGLContext] makeCurrentContext];

  [self resizeGL];
  [self updateProjection];
  [self updateModelView];

  if (zoom_value != dest_zoom) { zoom_value += (dest_zoom - zoom_value) / 4.0; }
  if (dest_offset_value[0] != offset_value[0]) { offset_value[0] += (dest_offset_value[0] - offset_value[0]) / 4.0; }
  if (dest_offset_value[1] != offset_value[1]) { offset_value[1] += (dest_offset_value[1] - offset_value[1]) / 4.0; }

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glClearColor(0xeb/255.0, 0xe7/255.0, 0xe1/255.0, 1);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glDisable(GL_DEPTH_TEST);

  glBegin(GL_LINES);
  glColor4f(0, 0, 0, 1);
  glVertex3f(content_center[0]-0.8, content_center[1], 0);
  glVertex3f(content_center[0]+0.8, content_center[1], 0);

  glVertex3f(content_center[0], content_center[1]-0.8, 0);
  glVertex3f(content_center[0], content_center[1]+0.8, 0);
  glEnd();

  usleep(10000);

  glFlush();
  [[self openGLContext] flushBuffer];
}

- (void) updateProjection {
  [[self openGLContext] makeCurrentContext];

  // set projection
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  glOrtho(content_bounds[0], content_bounds[1], content_bounds[2], content_bounds[3], 1, -1);
}

- (void) updateModelView {
  [[self openGLContext] makeCurrentContext];

  // move view
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  // glTranslatef(content_center[0], content_center[1], 0);
  glScalef(zoom_value, zoom_value, zoom_value);

  glRotatef(rotate[0], 1, 0, 0);
  glRotatef(rotate[1], 0, 1, 0);
  glRotatef(rotate[2], 0, 0, 1);

  // glTranslatef(-content_center[0], -content_center[1], 0);
  glTranslatef(offset_value[0], offset_value[1], 0);
}

- (void) resizeGL {
  [[self openGLContext] makeCurrentContext];
	NSRect rectView = [self convertRectToBacking:[[self superview] bounds]];
  [self setFrame:[[self superview] bounds]];
  glViewport(0, 0, rectView.size.width, rectView.size.height);
  // glViewport(0, 0, rectView.size.width, rectView.size.width);
  view_ratio = rectView.size.width / (float)rectView.size.height;
}

- (void) keyDown:(NSEvent *)theEvent {
    NSString *characters = [theEvent characters];
    if ([characters length]) {
      unichar character = [characters characterAtIndex:0];
      switch (character) {
      case 'a': case NSLeftArrowFunctionKey:  dest_offset_value[0] += (content_bounds[1] - content_bounds[0]) / 10000000. * zoom_value; break;
      case 'd': case NSRightArrowFunctionKey: dest_offset_value[0] -= (content_bounds[1] - content_bounds[0]) / 10000000. * zoom_value; break;
      case 'w': case NSUpArrowFunctionKey:    dest_offset_value[1] -= (content_bounds[3] - content_bounds[2]) / 10000000. * zoom_value; break;
      case 's': case NSDownArrowFunctionKey:  dest_offset_value[1] += (content_bounds[3] - content_bounds[2]) / 10000000. * zoom_value; break;
      case 'q':
      case 27: // esc
        // printf("dest_offset_value[1] = content_offset[1] = %f;\n", content_offset[1]);
        // printf("dest_offset_value[0] = content_offset[0] = %f;\n", content_offset[0]);
        printf("dest_zoom = zoom = %f;\n", zoom_value);
        printf("content_bounds = (%f,%f,%f,%f);\n", content_bounds[0], content_bounds[1], content_bounds[2], content_bounds[3]);
        // printf("content_center = (%f,%f);\n", content_center[0], content_center[1]);
        // printf("worldRotateX = %.5f\n", worldRotateX);
        // printf("worldRotateY = %.5f\n", worldRotateY);
        // printf("worldRotateZ = %.5f\n", worldRotateZ);
        exit(1);
        break;
		}
	}
}

- (void) mouseDown:(NSEvent *)theEvent {
  // prev_location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
}

- (void) mouseUp:(NSEvent *)theEvent {
  // prev_location.x = 0;
  // prev_location.y = 0;
}

- (void) mouseDragged:(NSEvent *)theEvent {
	// NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];

  // [self drawRect:[self convertRectToBacking:[self bounds]]];
  // prev_location = location;
}

- (void) scrollWheel:(NSEvent *)theEvent {
	float wheelDelta = [theEvent deltaX] +[theEvent deltaY] + [theEvent deltaZ];
	if (wheelDelta)
	{
		GLfloat deltaAperture = wheelDelta * -dest_zoom / 200.0f;
		dest_zoom -= deltaAperture;
		// if (dest_zoom < 0.1) dest_zoom = 0.1;
		[self setNeedsDisplay: YES];
	}
}

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder { return YES; }
- (BOOL)resignFirstResponder { return YES; }

- (void)animationTimer:(NSTimer *)timer {
	//time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
  [self drawRect:[self convertRectToBacking:[self bounds]]]; // redraw now instead dirty to enable updates during live resize
}

- (void) awakeFromNib {

  NSOpenGLPixelFormatAttribute windowedAttributes[] =
  {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFAAccelerated,
    NSOpenGLPFASampleBuffers, (NSOpenGLPixelFormatAttribute)(4),
    NSOpenGLPFASamples, (NSOpenGLPixelFormatAttribute)(4),
    NSOpenGLPFAColorSize, 32,
    NSOpenGLPFADepthSize, 24,
    0
  };

  NSOpenGLPixelFormat * windowedPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:windowedAttributes];
  NSAssert(windowedPixelFormat, @"Error: windowedPixelFormat is nil.");
  NSOpenGLContext * openGLContext = [[[NSOpenGLContext alloc] initWithFormat:windowedPixelFormat shareContext:nil] autorelease];
  [self setPixelFormat:windowedPixelFormat];
  [self setOpenGLContext:openGLContext];
  [openGLContext makeCurrentContext];

  NSLog(@"Setting up main window.");

  [windowedPixelFormat release];
  [self setWantsBestResolutionOpenGLSurface:YES];
  [self setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];

  [[self openGLContext] makeCurrentContext];

  if (content_bounds[0] == 100000000 || content_bounds[1] == -100000000) {
    extend_content_bounds(1, 1);
    extend_content_bounds(-1, -1);
  }

  content_center[0] = (content_bounds[0] + content_bounds[1]) / 2;
  content_center[1] = (content_bounds[2] + content_bounds[3]) / 2;

  printf("num_vertices = %d\n", num_vertices);
  printf("num_colours = %d\n", num_colours);
  printf("content_center = %f %f\n", content_center[0], content_center[1]);

  glHint(GL_LINE_SMOOTH_HINT, GL_FASTEST);
  glEnable(GL_LINE_SMOOTH);

  timer = [NSTimer timerWithTimeInterval:(1.0f/40.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
  [self resizeGL];

  [[NSApplication sharedApplication] activateIgnoringOtherApps:true];
}

@end

int main(int argc, char *argv[])
{
  return NSApplicationMain(argc,  (const char **) argv);
}
