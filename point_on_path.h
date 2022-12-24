
#ifndef POINT_ALONG_SHAPE_H
#define POINT_ALONG_SHAPE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <math.h>

#define PI 3.1415926535
#define PI2 3.1415926535*2.0

struct s_path;
enum thing_type {
  ACTOR,
  STOP,
};

struct s_thing {
  enum thing_type type;
  float x, y, angle, index_on_path;
  struct s_path * on_path;
};

struct s_actor {
  float x, y, angle, index_on_path;
  float width, height;
  float velocity;     // m/s
  float max_velocity; // m/s
  float acceleration; // m/s/s
  float max_acceleration; // 1g = 9.8066 m/s/s
  int num_segments;

  struct s_path * on_path;
  float perc_on_path;
  struct s_actor * next_actor;
  struct s_actor * prev_actor;

  struct s_stop * next_stop;
};

struct s_point {
  float x, y, angle;
};

struct s_pop { // point on path
  float x, y, angle, dist, index; // index is number of line segments plus percentage to next line segment
};

// struct s_stop {
//   float x, y, angle, index_on_path;
//   struct s_path * on_path;
// };

struct s_path {
  int num_points;
  struct s_point * points;
  int num_actors;
  struct s_actor * actors;
  // int num_stops;
  // struct s_stop * stops;
  int num_things;
  struct s_thing ** things;
};

extern int num_paths;
extern struct s_path * paths;

struct s_path * add_new_path(int num_points);
struct s_actor * add_new_actor_on_path(struct s_path * path, float x, float y, float velocity, float max_velocity, float acceleration, float max_acceleration);
struct s_thing * add_new_stop_on_path(struct s_path * path, float x, float y);

float point_dist(struct s_point * a, struct s_point * b);
float path_length(struct s_path * p);
void point_on_path(struct s_path * path, float x, float y, struct s_pop * ret);
void offset_along_path(struct s_path * path, struct s_pop * pop, float offset);
int test_if_other_actors_within(struct s_path * path, struct s_actor * actor, float distance);
void update_next_prev_actors(struct s_path * path);
void move_thing_to_its_path(struct s_thing * thing);

float index_distance(struct s_path * path, struct s_actor * a, struct s_actor * b);
float real_distance(struct s_path * path, struct s_actor * a, struct s_actor * b);

#ifdef __cplusplus
}
#endif

#endif
