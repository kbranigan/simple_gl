
#import <Cocoa/Cocoa.h>
#include "main.h"
#include "point_on_path.h"

#include <map>
#include <array>
#include <vector>
#include <string>
#include <sys/time.h>

timeval lastFrame = { 0, 0 };
float view_ratio = 1;
float rotate[3] = { 0, 0, 0 };
float path_circumference = 5000; // 5km

// GLfloat zoom_value = 0.5;
// GLfloat dest_zoom  = 0.5;
GLfloat offset_value[2]      = { 0, 0 };
GLfloat dest_offset_value[2] = { 0, 0 };

GLfloat zoom_value = .44;//.9;
GLfloat dest_zoom  = .44;//.9;
// GLfloat offset_value[2]      = { -2961.904785, 1954.159668 };
// GLfloat dest_offset_value[2] = { -2961.904785, 1954.159668 };

float scale_big = 5;

// struct s_path * mouse_path = NULL;

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

  timeval thisFrame;
  gettimeofday(&thisFrame, NULL);
  double elapsedTimeMs;
  elapsedTimeMs = (thisFrame.tv_sec - lastFrame.tv_sec) * 1000.0;    // sec to ms
  elapsedTimeMs += (thisFrame.tv_usec - lastFrame.tv_usec) / 1000.0; // us to ms
  if (lastFrame.tv_usec == 0) elapsedTimeMs = 0;
  gettimeofday(&lastFrame, NULL);
  // printf("%f\n", elapsedTimeMs);

  if (zoom_value != dest_zoom) { zoom_value += (dest_zoom - zoom_value) / 4.0; }
  if (dest_offset_value[0] != offset_value[0]) { offset_value[0] += (dest_offset_value[0] - offset_value[0]) / 4.0; }
  if (dest_offset_value[1] != offset_value[1]) { offset_value[1] += (dest_offset_value[1] - offset_value[1]) / 4.0; }

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glClearColor(0xeb/255.0, 0xe7/255.0, 0xe1/255.0, 1);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glDisable(GL_DEPTH_TEST);

  // glBegin(GL_LINES);
  // glColor4f(0, 0, 0, 1);
  // glVertex3f(content_center[0], content_center[1], 0);
  // glVertex3f(content_center[0] + 10000, content_center[1] + 10000, 0);
  // glEnd();

  for (int i = 0 ; i < num_paths ; i++) {
    struct s_path * path = paths[i];
    glBegin(GL_LINE_STRIP);
    glColor4f(0, 0, 0, 1);
    for (int j = 0 ; j < path->num_points ; j++) {
      glVertex3f(path->points[j].x, path->points[j].y, 0);
    }
    glEnd();

    update_next_prev_things(path);
    // glBegin(GL_LINES);
    // for (int j = 0 ; j < path->num_actors ; j++) {
    //   struct s_actor * actor = &path->actors[j];
    //   if (actor->next_actor != NULL) {
    //     glColor4f(1, 0, 0, 1);
    //     glVertex3f(actor->p.x, actor->p.y, 0);
    //     glColor4f(0, 1, 0, 1);
    //     glVertex3f(actor->next_actor->p.x, actor->next_actor->p.y, 0);
    //   }
    // }
    // glEnd();

    glBegin(GL_LINES);
    for (int j = 0 ; j < path->num_things ; j++) {
      struct s_thing * thing = path->things[j];

      if (thing->type == ACTOR) {
        struct s_actor * actor = (struct s_actor *)thing;

        if (actor->num_route_things == 0) continue;
        struct s_thing * dest_thing = actor->route_things[actor->route_step];

        if (dest_thing != NULL
         && actor->on_path == dest_thing->on_path
         && point_dist((struct s_point *)(&actor->p), (struct s_point *)(&dest_thing->p)) > 10.
          )
        {
          glVertex3f(actor->p.x, actor->p.y, 0);
          glVertex3f(dest_thing->p.x, dest_thing->p.y, 0);

          // float time_to_full_speed = (actor->max_velocity - actor->velocity) / fabs(actor->max_acceleration);
          // float dist_to_full_speed = actor->velocity * time_to_full_speed + 0.5 * fabs(actor->max_acceleration) * pow(time_to_full_speed, 2);

          struct s_pop p2 = copy_pop((struct s_thing *)actor);
          // offset_along_path(actor->on_path, &p2, dist_to_full_speed);
          // glVertex3f(actor->p.x, actor->p.y, 0);
          // glVertex3f(p2.x, p2.y, 0);

          float time_to_stop = (actor->velocity - dest_thing->velocity) / fabs(actor->max_acceleration);
          float dist_to_stop = actor->velocity * time_to_stop + 0.5 * -fabs(actor->max_acceleration) * pow(time_to_stop, 2);

          // p2 = copy_pop((struct s_thing *)actor);
          offset_along_path(actor->on_path, &p2, dist_to_stop);
          glVertex3f(actor->p.x, actor->p.y, 0);
          glVertex3f(p2.x, p2.y, 0);
        }
      }
    }
    glEnd();


    glBegin(GL_QUADS);
    for (int j = 0 ; j < path->num_things ; j++) {
      struct s_thing * thing = path->things[j];
      glColor4f(0.6 - 0.2 * j, 0.2 * j, 0, 0.6);
      // float hyp = sqrt((100 * 0.5) * (100 * 0.5) + (100 * 0.5) * (100 * 0.5));

      if (thing->acceleration > thing->max_acceleration) thing->acceleration = thing->max_acceleration;
      if (thing->acceleration < -thing->max_acceleration) thing->acceleration = -thing->max_acceleration;
      thing->velocity += thing->acceleration * (elapsedTimeMs / 1000.);
      if (thing->velocity > thing->max_velocity) thing->velocity = thing->max_velocity;
      if (thing->velocity < -thing->max_velocity) thing->velocity = -thing->max_velocity;
      offset_along_path(path, &thing->p, thing->velocity * (elapsedTimeMs / 1000.));

      if (thing->type == STOP)
      {
        struct s_stop * stop = (struct s_stop *)thing;
        float hyp = sqrt((stop->width * 0.5) * (stop->width * 0.5) + (stop->height * 0.5) * (stop->height * 0.5));
        if (scale_big) hyp *= scale_big; // just so it's visible
        
        glColor4f(0.6 - 0.2 * j, 0.2 * j, 0, 0.6);
        // glVertex3f(thing->p.x + 30, thing->p.y + 30, 0);
        // glVertex3f(thing->p.x + 30, thing->p.y - 30, 0);
        // glVertex3f(thing->p.x - 30, thing->p.y - 30, 0);
        // glVertex3f(thing->p.x - 30, thing->p.y + 30, 0);

        for (int k = 0 ; k < stop->num_segments ; k++) {
          struct s_pop p2 = copy_pop((struct s_thing *)stop);
          offset_along_path(path, &p2, -(k * stop->height * scale_big));

          float tla, tra, bra, bla;

          // tla = atan2( stop->height, -stop->width); glVertex3f(p2.x + cos(tla + p2.angle - PI * .5) * hyp, p2.y + sin(tla + p2.angle - PI * .5) * hyp, 0);
          // tra = atan2( stop->height,  stop->width); glVertex3f(p2.x + cos(tra + p2.angle - PI * .5) * hyp, p2.y + sin(tra + p2.angle - PI * .5) * hyp, 0);
          // bra = atan2(-stop->height,  stop->width); glVertex3f(p2.x + cos(bra + p2.angle - PI * .5) * hyp, p2.y + sin(bra + p2.angle - PI * .5) * hyp, 0);
          // bla = atan2(-stop->height, -stop->width); glVertex3f(p2.x + cos(bla + p2.angle - PI * .5) * hyp, p2.y + sin(bla + p2.angle - PI * .5) * hyp, 0);

          tla = atan2( stop->height, -stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * stop->path_offset * scale_big) + cos(tla + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * stop->path_offset * scale_big) + sin(tla + p2.angle - PI * .5) * hyp, 0);
          tra = atan2( stop->height,  stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * stop->path_offset * scale_big) + cos(tra + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * stop->path_offset * scale_big) + sin(tra + p2.angle - PI * .5) * hyp, 0);
          bra = atan2(-stop->height,  stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * stop->path_offset * scale_big) + cos(bra + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * stop->path_offset * scale_big) + sin(bra + p2.angle - PI * .5) * hyp, 0);
          bla = atan2(-stop->height, -stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * stop->path_offset * scale_big) + cos(bla + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * stop->path_offset * scale_big) + sin(bla + p2.angle - PI * .5) * hyp, 0);

          tla = atan2( stop->height, -stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * -stop->path_offset * scale_big) + cos(tla + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * -stop->path_offset * scale_big) + sin(tla + p2.angle - PI * .5) * hyp, 0);
          tra = atan2( stop->height,  stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * -stop->path_offset * scale_big) + cos(tra + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * -stop->path_offset * scale_big) + sin(tra + p2.angle - PI * .5) * hyp, 0);
          bra = atan2(-stop->height,  stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * -stop->path_offset * scale_big) + cos(bra + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * -stop->path_offset * scale_big) + sin(bra + p2.angle - PI * .5) * hyp, 0);
          bla = atan2(-stop->height, -stop->width); glVertex3f(p2.x + (cos(p2.angle + PI * .5) * -stop->path_offset * scale_big) + cos(bla + p2.angle - PI * .5) * hyp, p2.y + (sin(p2.angle + PI * .5) * -stop->path_offset * scale_big) + sin(bla + p2.angle - PI * .5) * hyp, 0);
          // printf("%d : %f\n", k, p2.angle - PI * .5);
        }
      }
      else if (thing->type == ACTOR)
      {
        struct s_actor * actor = (struct s_actor *)thing;
        float hyp = sqrt((actor->width * 0.5) * (actor->width * 0.5) + (actor->height * 0.5) * (actor->height * 0.5));
        if (scale_big) hyp *= scale_big; // just so it's visible
        glColor4f(0.6 - 0.2 * j, 0.2 * j, 0, 0.6);
        // float full_length = path_length(path);
        // float perc = 0, angle = actor->p.angle;
        // int a_index;
        // actor_on_path(path, actor);
        // printf("%d: %f %f\n", j, p.x, p.y);

        if (actor->num_route_things > 0) {
          struct s_thing * dest_thing = actor->route_things[actor->route_step];
          float dist_to_destination = real_distance(actor->on_path, (struct s_thing *)actor, dest_thing);

          // float time_to_full_speed = (actor->max_velocity - actor->velocity) / fabs(actor->max_acceleration);
          // float dist_to_full_speed = actor->velocity * time_to_full_speed + 0.5 * fabs(actor->max_acceleration) * pow(time_to_full_speed, 2);

          float time_to_stop = (actor->velocity - dest_thing->velocity) / fabs(actor->max_acceleration);
          float dist_to_stop = actor->velocity * time_to_stop + 0.5 * -fabs(actor->max_acceleration) * pow(time_to_stop, 2);

          if (dist_to_destination < 1) {
            actor->acceleration = dest_thing->acceleration;
            actor->route_step ++;
            if (actor->route_step >= actor->num_route_things) {
              actor->route_step = 0;
            }
            printf("%d\n", actor->route_step);
          } else if (dist_to_stop < dist_to_destination) {
            actor->acceleration = fabs(actor->max_acceleration);
          } else if (dist_to_stop > dist_to_destination) {
            actor->acceleration = -fabs(actor->max_acceleration);
          }
          // kbfu i don't like when the dist_to_stop is close to the dist_to_destination then how the acceleration flip flops between min and max, it's not accurate, but it works for now
        }

        for (int k = 0 ; k < actor->num_segments ; k++) {
          struct s_pop p2 = copy_pop((struct s_thing *)actor);
          offset_along_path(path, &p2, -(k * actor->height * scale_big));

          // int g2 = test_if_other_actors_within(path, actor, actor->height * 2);
          // if (point_dist((struct s_point *)actor, (struct s_point *)actor->next_actor) < actor->height * 1.1) {
          //   actor->velocity = actor->next_actor->velocity;
          // } else {

          // int g = test_if_other_actors_within(path, actor, actor->height);
          // g should never be true, obviously

          // glColor4f(0.6 - 0.2 * j, 0.1 * k, g, 0.6);
          // glColor4f(g, g, g, 1);
          // if (g) {
          //   actor->velocity *= 0.85;
          // } else {
          //   actor->velocity *= 1.01;
          // }

          // printf("%f %f\n", actor->p.index, actor->p.angle);

          //   p = point_on_path(path, actor->p.x, actor->p.y, &angle, &perc, &a_index);
          //   if (k == 0) {
          //     actor->p.x = p.x;
          //     actor->p.y = p.y;
          //     actor->p.angle = angle;
          //   }
          //   float dx = actor->p.x - path->points[a_index].x;
          //   float dy = actor->p.y - path->points[a_index].y;
          //   float dist = sqrt(dx*dx + dy*dy);
          //   for (int l = a_index - 1 ; l > 0 ; l--) {
          //     dist += point_dist(&path->points[l], &path->points[l + 1]);
          //     if (dist > actor->height * 1.1 * k) {
          //       p.x = path->points[l].x;
          //       p.y = path->points[l].y;
          //       p = point_on_path(path, p.x, p.y, &angle, &perc, &a_index);
          //       break;
          //     }
          //   }
          //   printf("%d: %f\n", k, angle);
          //   // printf("%d: %f %f\n", k, dist, full_length);

          float tla = atan2( actor->height, -actor->width); glVertex3f(p2.x + cos(tla + p2.angle - PI * .5) * hyp, p2.y + sin(tla + p2.angle - PI * .5) * hyp, 0);
          float tra = atan2( actor->height,  actor->width); glVertex3f(p2.x + cos(tra + p2.angle - PI * .5) * hyp, p2.y + sin(tra + p2.angle - PI * .5) * hyp, 0);
          float bra = atan2(-actor->height,  actor->width); glVertex3f(p2.x + cos(bra + p2.angle - PI * .5) * hyp, p2.y + sin(bra + p2.angle - PI * .5) * hyp, 0);
          float bla = atan2(-actor->height, -actor->width); glVertex3f(p2.x + cos(bla + p2.angle - PI * .5) * hyp, p2.y + sin(bla + p2.angle - PI * .5) * hyp, 0);
        }
      }
    }
    glEnd();
  }
  // exit(1);

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
  glScalef(zoom_value, zoom_value * view_ratio, zoom_value);

  // glRotatef(rotate[0], 1, 0, 0);
  // glRotatef(rotate[1], 0, 1, 0);
  // glRotatef(rotate[2], 0, 0, 1);

  // glTranslatef(-content_center[0], -content_center[1], 0);
  glTranslatef(offset_value[0], offset_value[1], 0);
}

- (void) resizeGL {
  [[self openGLContext] makeCurrentContext];
	NSRect rectView = [self convertRectToBacking:[[self superview] bounds]];
  [self setFrame:[[self superview] bounds]];
  // glViewport(0, 0, rectView.size.width, rectView.size.height);
  glViewport(0, 0, rectView.size.width, rectView.size.height);
  view_ratio = rectView.size.width / (float)rectView.size.height;
}

- (void) keyDown:(NSEvent *)theEvent {
  NSString *characters = [theEvent characters];
  if ([characters length]) {
    unichar character = [characters characterAtIndex:0];
    switch (character) {
      case 'a': case NSLeftArrowFunctionKey:  dest_offset_value[0] += (content_bounds[1] - content_bounds[0]) / 10. * zoom_value; break;
      case 'd': case NSRightArrowFunctionKey: dest_offset_value[0] -= (content_bounds[1] - content_bounds[0]) / 10. * zoom_value; break;
      case 'w': case NSUpArrowFunctionKey:    dest_offset_value[1] -= (content_bounds[3] - content_bounds[2]) / 10. * zoom_value; break;
      case 's': case NSDownArrowFunctionKey:  dest_offset_value[1] += (content_bounds[3] - content_bounds[2]) / 10. * zoom_value; break;
      // case 'b':
      //   scale_big = !scale_big; 
      //   // paths[0].actors[0].acceleration = paths[0].actors[0].max_acceleration; //0.5;
      //   // paths[0].actors[0].velocity = paths[0].actors[0].max_velocity; //0.5;
      //   // printf("%f %f\n", paths[0].actors[0].velocity, paths[0].actors[0].acceleration);
      //   break;
      case 'q':
      case 27: // esc
        // printf("dest_offset_value[1] = content_offset[1] = %f;\n", content_offset[1]);
        // printf("dest_offset_value[0] = content_offset[0] = %f;\n", content_offset[0]);
        printf("dest_zoom = zoom = %f;\n", zoom_value);
        printf("content_bounds = (%f,%f,%f,%f);\n", content_bounds[0], content_bounds[1], content_bounds[2], content_bounds[3]);
        printf("offset_value = (%f,%f);\n", offset_value[0], offset_value[1]);
        // printf("content_center = (%f,%f);\n", content_center[0], content_center[1]);
        // printf("worldRotateX = %.5f\n", worldRotateX);
        // printf("worldRotateY = %.5f\n", worldRotateY);
        // printf("worldRotateZ = %.5f\n", worldRotateZ);
        exit(1);
        break;
		}
	}
}

- (void) keyUp:(NSEvent *)theEvent {
  NSString *characters = [theEvent characters];
  if ([characters length]) {
    unichar character = [characters characterAtIndex:0];
    switch (character) {
      case 'e':
        // paths[0].actors[0].acceleration = 0.;
        // printf("%f %f\n", paths[0].actors[0].velocity, paths[0].actors[0].acceleration);
        break;
        break;
      default:
        break;
    }
  }
}

- (void) mouseDown:(NSEvent *)theEvent {
  // prev_location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
}

- (void) mouseUp:(NSEvent *)theEvent {
  NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  NSRect rectView = [self convertRectToBacking:[[self superview] bounds]];

  struct s_point world_point;
  world_point.x = (((location.x * 2.) / rectView.size.width)  * (content_bounds[1] - content_bounds[0]) - (content_bounds[1] - content_bounds[0]) / 2.) / zoom_value - offset_value[0];
  world_point.y = (((location.y * 2.) / rectView.size.height) * (content_bounds[3] - content_bounds[2]) - (content_bounds[3] - content_bounds[2]) / 2.) / (zoom_value * view_ratio) - offset_value[1];
  printf("%f %f\n", world_point.x, world_point.y);

  // add_path_point(mouse_path, world_point.x, world_point.y);
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
    NSOpenGLPFADoubleBuffer, NSOpenGLPFAAccelerated, NSOpenGLPFASampleBuffers, (NSOpenGLPixelFormatAttribute)(4),
    NSOpenGLPFASamples, (NSOpenGLPixelFormatAttribute)(4), NSOpenGLPFAColorSize, 32, NSOpenGLPFADepthSize, 24, 0
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

  float radius = path_circumference / 3.141592653589793 / 2;

  if (content_bounds[0] == 100000000 || content_bounds[1] == -100000000) {
    extend_content_bounds(radius, radius);
    extend_content_bounds(-radius, -radius);
  }

  struct s_path * path = add_new_path(401);
  for (int i = 0 ; i < path->num_points ; i++) {
    path->points[i].x = cos(i / (path->num_points - 1.) * 3.1415 * 2.) * radius;
    path->points[i].y = sin(i / (path->num_points - 1.) * 3.1415 * 2.) * radius;
  }

  // struct s_path * path2 = add_new_path(401);
  // for (int i = 0 ; i < path2->num_points ; i++) {
  //   path2->points[i].x = cos(i / (path2->num_points - 1.) * 3.1415 * 2.) * radius + radius;
  //   path2->points[i].y = sin(i / (path2->num_points - 1.) * 3.1415 * 2.) * radius;
  // }

  // mouse_path = add_new_path(0);

  float max_velocity = 8000000 / 3600.;    // 8000km/hr
  float max_acceleration = 9.8066 * 30; // 3g
  // float max_velocity = 80000 / 3600.;    // 80km/hr
  // float max_acceleration = 9.8066 * 0.3; // 0.3g
  
  // add_new_actor_on_path(path,  0.707 * radius, -0.707 * radius, max_velocity, max_acceleration);
  // add_new_actor_on_path(path, -0.707 * radius, -0.707 * radius, max_velocity, max_acceleration);
  struct s_actor * actor = add_new_actor_on_path(path,  0.707 * radius, -0.707 * radius, max_velocity, max_acceleration);
  // add_new_actor_on_path(path, -0.707 * radius,  0.707 * radius, max_velocity, max_acceleration);

  struct s_actor * hehe = add_new_actor_on_path(path, 0.707 * radius, 0.707 * radius, max_velocity, max_acceleration);
  hehe->num_segments = 1;
  hehe->velocity = hehe->max_velocity = 100;
  hehe->max_acceleration = 0;

  struct s_stop * stopt = add_new_stop_on_path(path, 0, radius);
  struct s_stop * stopl = add_new_stop_on_path(path, -radius, 0);
  struct s_stop * stopb = add_new_stop_on_path(path, 0, -radius);
  struct s_stop * stopr = add_new_stop_on_path(path, radius, 0);

  // add_thing_to_actor_route(actor, (struct s_thing *)hehe);
  add_thing_to_actor_route(actor, (struct s_thing *)stopt);
  add_thing_to_actor_route(actor, (struct s_thing *)stopl);
  add_thing_to_actor_route(actor, (struct s_thing *)stopb);
  add_thing_to_actor_route(actor, (struct s_thing *)stopr);

  // add_new_actor_on_path(path2,  0.707 * radius + radius, -0.707 * radius, max_velocity, max_acceleration);
  // add_new_actor_on_path(path2, -0.707 * radius + radius, -0.707 * radius, max_velocity, max_acceleration);
  // add_new_actor_on_path(path2,  0.707 * radius + radius,  0.707 * radius, max_velocity, max_acceleration);
  // add_new_actor_on_path(path2, -0.707 * radius + radius,  0.707 * radius, max_velocity, max_acceleration);

  // add_new_stop_on_path(path2, radius + radius, 0);
  // add_new_stop_on_path(path2, -radius + radius, 0);
  // add_new_stop_on_path(path2, 0 + radius, radius);
  // add_new_stop_on_path(path2, 0 + radius, -radius);

  // add_new_actor_on_path(path, -0.5,  0.3, 0.4);
  // add_new_actor_on_path(path,  0.0, -0.3, 0.05);

  // add_new_actor_on_path(path,  0.5,  0.3, 0.01);
  // add_new_actor_on_path(path, -0.5,  0.3, 0.015);
  // add_new_actor_on_path(path,  0.0, -0.3, 0.005);

  content_center[0] = (content_bounds[0] + content_bounds[1]) / 2;
  content_center[1] = (content_bounds[2] + content_bounds[3]) / 2;
  printf("content_center = %f %f\n", content_center[0], content_center[1]);

  glHint(GL_LINE_SMOOTH_HINT, GL_FASTEST);
  glEnable(GL_LINE_SMOOTH);

  timer = [NSTimer timerWithTimeInterval:(1.0f/40.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
  [self resizeGL];

  srand48(time(NULL));

  [[NSApplication sharedApplication] activateIgnoringOtherApps:true];
}

@end

int main(int argc, char *argv[])
{
  return NSApplicationMain(argc,  (const char **) argv);
}
