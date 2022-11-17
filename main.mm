
#import <Cocoa/Cocoa.h>
#include "main.h"

#include <map>
#include <array>
#include <vector>
#include <string>

#ifdef USE_SHADER
GLuint vshader, fshader, program;
GLint status;
GLuint vertex_vao = 0;
GLuint vertex_vbo = 0;
// GLuint colour_vbo = 0;

GLuint zoom_uniform = 0;
GLuint content_ratio_uniform = 0;
GLuint view_ratio_uniform = 0;
GLuint offset_uniform = 0;
GLuint content_bounds_uniform = 0;
#else
#endif

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
  #ifdef USE_SHADER
  #else  
  [self updateProjection];
  [self updateModelView];
  #endif

  if (zoom_value != dest_zoom) { zoom_value += (dest_zoom - zoom_value) / 4.0; }
  if (dest_offset_value[0] != offset_value[0]) { offset_value[0] += (dest_offset_value[0] - offset_value[0]) / 4.0; }
  if (dest_offset_value[1] != offset_value[1]) { offset_value[1] += (dest_offset_value[1] - offset_value[1]) / 4.0; }

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glClearColor(0xeb/255.0, 0xe7/255.0, 0xe1/255.0, 1);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glDisable(GL_DEPTH_TEST);

  #ifdef USE_SHADER
  glUseProgram(program);
  glUniform1f(zoom_uniform, zoom_value);
  glUniform2f(offset_uniform, offset_value[0], offset_value[1]);
  glUniform1f(view_ratio_uniform, view_ratio);
  glUniform1f(content_ratio_uniform, (content_bounds[1] - content_bounds[0]) / (content_bounds[3] - content_bounds[2]));
  glUniform4f(content_bounds_uniform, content_bounds[0], content_bounds[1], content_bounds[2], content_bounds[3]);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo);
  // glBindBuffer(GL_ARRAY_BUFFER, colour_vbo);
  // glDrawArrays(GL_TRIANGLES, 0, num_vertices);
  // glDrawArrays(GL_POINTS, 0, num_vertices);
  glDrawArrays(GL_LINES, 0, num_vertices);
  #else
  glBegin(GL_LINES);
  glColor4f(0, 0, 0, 1);
  glVertex3f(content_center[0]-1, content_center[1], 0);
  glVertex3f(content_center[0]+1, content_center[1], 0);
  glEnd();
  #endif

  glBegin(GL_LINES);
  glColor4f(0, 0, 0, 1);
  glVertex3f(content_center[0]-1, content_center[1], 0);
  glVertex3f(content_center[0]+1, content_center[1], 0);
  glEnd();

  // glBegin(GL_POINTS);
  // glColor4f(1, 0, 0, .5);
  // for (int i = 0 ; i < dwg.num_entities ; i++) {
  //   if (dwg.object[i].type == DWG_TYPE_POINT) {
  //     auto colour = layerColours.find(dwg.object[i].tio.entity->layer->obj->tio.object->tio.LAYER->name);
  //     if (colour == layerColours.end()) continue;
  //     glColor4fv(&colour->second[0]);
  //     Dwg_Entity_POINT * point = dwg.object[i].tio.entity->tio.POINT;
  //     // if (strcmp(dwg.object[i].tio.entity->layer->obj->tio.object->tio.LAYER->name, layer_name) != 0) continue;
  //     glVertex3f(point->x - content_center[0], point->y - content_center[1], 0);
  //   } else if (dwg.object[i].type == DWG_TYPE_INSERT) {
  //     auto colour = layerColours.find(dwg.object[i].tio.entity->layer->obj->tio.object->tio.LAYER->name);
  //     if (colour == layerColours.end()) continue;
  //     glColor4fv(&colour->second[0]);
  //     Dwg_Entity_INSERT * insert = dwg.object[i].tio.entity->tio.INSERT;
  //     // if (strcmp(dwg.object[i].tio.entity->layer->obj->tio.object->tio.LAYER->name, layer_name) != 0) continue;
  //     glVertex3f(insert->ins_pt.x - content_center[0], insert->ins_pt.y - content_center[1], 0);
  //   } else if (dwg.object[i].type == DWG_TYPE_CIRCLE) {
  //     auto colour = layerColours.find(dwg.object[i].tio.entity->layer->obj->tio.object->tio.LAYER->name);
  //     if (colour == layerColours.end()) continue;
  //     glColor4fv(&colour->second[0]);
  //     Dwg_Entity_CIRCLE * arc = dwg.object[i].tio.entity->tio.CIRCLE;
  //     // if (strcmp(dwg.object[i].tio.entity->layer->obj->tio.object->tio.LAYER->name, layer_name) != 0) continue;
  //     glVertex3f(arc->center.x - content_center[0], arc->center.y - content_center[1], 0);
  //   }
  // }
  // glEnd();

  usleep(10000);

  glFlush();
  [[self openGLContext] flushBuffer];
}

- (void) updateProjection {
  [[self openGLContext] makeCurrentContext];

  // set projection
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  // #ifdef USE_GLKIT
  // GLKMatrix4 m4pres = GLKMatrix4MakePerspective(10, [self bounds].size.width/[self bounds].size.height, 0.001, 1000);
  // glMultMatrixf(m4pres.m);
  // GLKMatrix4 m4look = GLKMatrix4MakeLookAt(center_lng, center_lat, 10, center_lng, center_lat, 0, 0, -1, 0);
  // glMultMatrixf(m4look.m);
  // #else
  // gluPerspective(10, [self bounds].size.width/[self bounds].size.height, 0.001, 1000);
  // gluLookAt(center_lng, center_lat, 10, center_lng, center_lat, 0, 0, 1, 0);
  // gluLookAt(content_center[0], content_center[1], 10, content_center[0], content_center[1], 0, 0, 1, 0);
  // gluLookAt(0, 0, 10, 0, 0, 0, 0, 1, 0);
  // #endif
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
    // #ifdef USE_SHADER
    // NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,
    // #else
    // NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
    // #endif
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

  #ifdef USE_SHADER
  vshader = glCreateShader(GL_VERTEX_SHADER);
    const char * vertex_shader_source = 
    "#version 410 core\n"
    "layout (location = 0) in vec3 vertex_position;\n"
    // "layout (location = 1) in vec3 vertex_colour;\n"
    // "out vec3 colour;\n"
    "uniform float zoom;\n"
    "uniform vec2 offset;\n"
    "uniform float view_ratio;\n"
    "uniform float content_ratio;\n"
    "uniform vec4 content_bounds;\n"
    "void main()\n"
    "{\n"
    // "  colour = vertex_colour;\n"
    "  gl_Position = vec4(\n"
    // "    ((vertex_position[0] - content_bounds[0]) / (content_bounds[1] - content_bounds[0]) * 2 - 1) * zoom * content_ratio / view_ratio + offset[0],\n"
    "    ((vertex_position[0] - content_bounds[0]) / (content_bounds[1] - content_bounds[0]) * 2 - 1) * zoom + offset[0],\n"
    "    ((vertex_position[1] - content_bounds[2]) / (content_bounds[3] - content_bounds[2]) * 2 - 1) * zoom * view_ratio + offset[1],\n"
    "    vertex_position[2], 1.0);\n"
    "}\n"
  ;
  glShaderSource(vshader, 1, &vertex_shader_source, NULL);
  glCompileShader(vshader);
  glGetShaderiv(vshader, GL_COMPILE_STATUS, &status);
  char infoLog[512] = "";
  glGetShaderInfoLog(vshader, 512, NULL, infoLog);
  if (strlen(infoLog) > 0) printf("%s\n", infoLog);
  if (status != GL_TRUE) { fprintf(stderr, "vertex_shader_source failed\n"); exit(1); }

  fshader = glCreateShader(GL_FRAGMENT_SHADER);
  const char * fragment_shader_source = 
    "#version 410 core\n"
    // "in vec3 colour;\n"
    "out vec4 frag_colour;\n"
    "void main()\n"
    "{\n"
    // "  frag_colour = vec4(colour, 1.0);\n"
    "  frag_colour = vec4(0, 0, 0, 1.0);\n"
    "}\n"
  ;
  glShaderSource(fshader, 1, &fragment_shader_source, NULL); // fragment_shader_source is a GLchar* containing glsl shader source code
  glCompileShader(fshader);
  glGetShaderiv(fshader, GL_COMPILE_STATUS, &status);
  glGetShaderInfoLog(fshader, 512, NULL, infoLog);
  if (strlen(infoLog) > 0) printf("%s\n", infoLog);
  if (status != GL_TRUE) { fprintf(stderr, "fragment_shader_source failed\n"); exit(1); }

  program = glCreateProgram();

  glAttachShader(program, vshader);
  glAttachShader(program, fshader);
  glLinkProgram(program);
  glGetProgramiv(program, GL_LINK_STATUS, &status);
  glGetProgramInfoLog(program, 512, NULL, infoLog);
  if (strlen(infoLog) > 0) printf("%s\n", infoLog);
  if (status != GL_TRUE) { fprintf(stderr, "glLinkProgram failed\n"); exit(1); }
  glUseProgram(program);
  zoom_uniform = glGetUniformLocation(program, "zoom");
  content_ratio_uniform = glGetUniformLocation(program, "content_ratio");
  view_ratio_uniform = glGetUniformLocation(program, "view_ratio");
  offset_uniform = glGetUniformLocation(program, "offset");
  content_bounds_uniform = glGetUniformLocation(program, "content_bounds");
  #endif

  #ifdef USE_SHADER
  glGenBuffers(1, &vertex_vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo);
  glBufferData(GL_ARRAY_BUFFER, num_vertices * sizeof(GLfloat), points, GL_STATIC_DRAW);

  // glGenBuffers(1, &colour_vbo);
  // glBindBuffer(GL_ARRAY_BUFFER, colour_vbo);
  // glBufferData(GL_ARRAY_BUFFER, num_vertices * sizeof(GLfloat), colours, GL_STATIC_DRAW);

  glGenVertexArrays(1, &vertex_vao);
  glBindVertexArray(vertex_vao);
  glEnableVertexAttribArray(0);
  // glEnableVertexAttribArray(1);
  glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
  // glBindBuffer(GL_ARRAY_BUFFER, colour_vbo);
  // glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, NULL);

  // free(points);
  // free(colours);
  #endif

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
