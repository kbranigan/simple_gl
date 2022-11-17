
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

@interface BasicOpenGLView : NSOpenGLView {
    NSTimer * timer;
}

- (void) resizeGL;
- (void) keyDown:(NSEvent *)theEvent;
- (void) mouseDown:(NSEvent *)theEvent;
- (void) mouseUp:(NSEvent *)theEvent;
- (void) mouseDragged:(NSEvent *)theEvent;
- (void) scrollWheel:(NSEvent *)theEvent;
- (void) drawRect:(NSRect)rect;

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (void) animationTimer:(NSTimer *)timer;
- (void) awakeFromNib;

@end
