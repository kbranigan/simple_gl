
#ifndef POINT_ALONG_SHAPE_H
#define POINT_ALONG_SHAPE_H

#include <math.h>

#define PI 3.1415926535
#define PI2 3.1415926535*2.0

struct s_path;
enum thing_type {
  ACTOR,
  STOP,
};

struct s_point {
  float x, y;
};

struct s_pop { // point on path
  float x, y, angle, index, dist; // index is number of line segments plus percentage to next line segment
};

struct s_thing {
  enum thing_type type;
  struct s_pop p;
  struct s_path * on_path;
  struct s_thing * next_thing;
  struct s_thing * prev_thing;
  float velocity;     // m/s
  float max_velocity; // m/s
  float acceleration; // m/s/s
  float max_acceleration; // 1g = 9.8066 m/s/s
};

struct s_actor {
  enum thing_type type;
  struct s_pop p;
  struct s_path * on_path;
  struct s_thing * next_thing;
  struct s_thing * prev_thing;
  float velocity; // m/s
  float max_velocity; // m/s
  float acceleration; // m/s/s
  float max_acceleration; // 1g = 9.8066 m/s/s

  ////////////////////

  float width, height;
  int num_segments;

  int route_step;
  int num_route_things;
  struct s_thing ** route_things;
  // struct s_route route;
};

struct s_stop {
  enum thing_type type;
  struct s_pop p;
  struct s_path * on_path;
  struct s_thing * next_thing;
  struct s_thing * prev_thing;
  float velocity; // m/s
  float max_velocity; // m/s
  float acceleration; // m/s/s
  float max_acceleration; // 1g = 9.8066 m/s/s

  ////////////////////

  float width, height;
  int num_segments;
  float path_offset; // left/right side
};

struct s_path {
  float path_length;

  int num_points;
  struct s_point * points;
  int num_things;
  struct s_thing ** things;

  // paths must start from the end of another
  // int num_next_paths;
  // struct s_path ** next_paths; // if path loops, it connects to itself only
};

extern int num_paths;
extern struct s_path ** paths;

struct s_path * add_new_path(int num_points);
void add_path_point(struct s_path * path, float x, float y);
struct s_actor * add_new_actor_on_path(struct s_path * path, float x, float y, float max_velocity, float max_acceleration);
struct s_stop * add_new_stop_on_path(struct s_path * path, float x, float y);
void remove_thing_from_path(struct s_path * path, struct s_thing * thing);

void add_thing_to_actor_route(struct s_actor * actor, struct s_thing * thing);
struct s_pop copy_pop(struct s_thing * t);

float point_dist(struct s_point * a, struct s_point * b);
float point_dist(struct s_pop * a, struct s_pop * b);
float path_length(struct s_path * p);
void point_on_path(struct s_path * path, float x, float y, struct s_pop * ret);
void offset_along_path(struct s_path * path, struct s_pop * pop, float offset);
void update_next_prev_things(struct s_path * path);
void move_thing_onto_its_path(struct s_thing * thing);

int index_of_thing(struct s_path * path, struct s_thing * thing);
float index_distance(struct s_path * path, struct s_thing * a, struct s_thing * b);
float real_distance(struct s_path * path, struct s_thing * a, struct s_thing * b);

#endif
