
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "point_on_path.h"

int num_paths = 0;
struct s_path * paths = NULL;

struct s_path * add_new_path(int num_points) {
  num_paths ++;
  paths = (struct s_path *)realloc((void *)paths, sizeof(struct s_path) * num_paths);
  struct s_path * path = &paths[num_paths - 1];
  path->num_points = num_points;
  path->points = (struct s_point *)malloc(sizeof(struct s_point) * path->num_points);

  path->num_actors = 0;
  path->actors = NULL;
  return path;
};

struct s_actor * add_new_actor_on_path(struct s_path * path, float x, float y, float velocity, float max_velocity, float acceleration, float max_acceleration) {
  path->num_actors ++;
  path->actors = (struct s_actor *)realloc((void *)path->actors, sizeof(struct s_actor) * path->num_actors);
  struct s_actor * actor = &path->actors[path->num_actors - 1];
  memset(actor, 0, sizeof(struct s_actor));
  struct s_pop p;
  point_on_path(path, x, y, &p); //, &actor->angle, &actor->perc_on_path, NULL);
  actor->x = p.x;
  actor->y = p.y;
  actor->angle = p.angle;
  actor->index_on_path = p.index;
  actor->on_path = path;
  // actor->perc_on_path = 0;
  actor->num_segments = 1;
  actor->width = 50;
  actor->height = 250;
  actor->velocity = velocity;
  actor->max_velocity = max_velocity;
  actor->acceleration = acceleration;
  actor->max_acceleration = max_acceleration;
  return actor;
}

struct s_thing * add_new_stop_on_path(struct s_path * path, float x, float y) {
  path->num_things ++;
  path->things = (struct s_thing**)realloc((void *)path->things, sizeof(struct s_thing *) * path->num_things);
  struct s_thing * thing = malloc(sizeof(struct s_thing));
  path->things[path->num_things - 1] = thing;
  thing->type = STOP;
  thing->x = x;
  thing->y = y;
  thing->on_path = path;
  move_thing_to_its_path(thing);
  return thing;
}

float point_dist(struct s_point * a, struct s_point * b) {
  float dx = b->x - a->x;
  float dy = b->y - a->y;
  return sqrt(dx*dx + dy*dy);
}

float path_length(struct s_path * p) {
  float full_length = 0;
  for (int i = 0 ; i < p->num_points - 1 ; i++)
  {
    float dx = p->points[i+1].x - p->points[i].x;
    float dy = p->points[i+1].y - p->points[i].y;
    full_length += sqrt(dx*dx + dy*dy);
  }
  return full_length;
}

void point_on_path(struct s_path * path, float x, float y, struct s_pop * ret) {

  ret->dist = 10000;
  ret->angle = 0;

  // float dist2_m;
  float dx, dy, dist1_2, dist1_m, angle1_2, angle1_m, angle2_m, angle_m_1_2, angle_1_2_m, dist_g;

  for (int i = 0 ; i < path->num_points - 1 ; i++) {
    struct s_point * a = &path->points[i];
    struct s_point * b = &path->points[i+1];
    dx = b->x - a->x;
    dy = b->y - a->y;
    dist1_2 = sqrt(dx*dx + dy*dy);
    angle1_2 = atan2(dy, dx);

    dx = x - a->x;
    dy = y - a->y;
    dist1_m = sqrt(dx*dx + dy*dy);
    angle1_m = atan2(dy, dx);

    dx = x - b->x;
    dy = y - b->y;
    // dist2_m = sqrt(dx*dx + dy*dy);
    angle2_m = atan2(dy, dx);

    angle_m_1_2 = -1 * (angle1_m - angle1_2);
    angle_1_2_m = -1 * (angle1_2 - angle2_m);

    if (angle_m_1_2 > 3.141592654) angle_m_1_2 -= 6.283185308;
    if (angle_m_1_2 < -3.141592654) angle_m_1_2 += 6.283185308;

    if (angle_1_2_m > 3.141592654) angle_1_2_m -= 6.283185308;
    if (angle_1_2_m < -3.141592654) angle_1_2_m += 6.283185308;

    dist_g = sin(angle_m_1_2) * dist1_m; // length of perpendicular (law of sines)

    // if (fabs(angle_m_1_2) > 1.570796327) continue; // i donno this broke it or something
    if (fabs(angle_1_2_m) < 1.570796327) continue;

    if (fabs(dist_g) < fabs(ret->dist)) {
      ret->x = x + cos(angle1_2+1.570796327) * dist_g;
      ret->y = y + sin(angle1_2+1.570796327) * dist_g;
      ret->index = i + dist1_m / dist1_2;
      ret->dist = dist_g;
      ret->angle = angle1_2;
    }
  }
}

void move_thing_to_its_path(struct s_thing * thing) {
  if (thing == NULL || thing->on_path == NULL) { fprintf(stderr, "move_thing_to_path bad input\n"); exit(1); }
  struct s_pop pop;
  point_on_path(thing->on_path, thing->x, thing->y, &pop);
  thing->x = pop.x;
  thing->y = pop.y;
  thing->angle = pop.angle;
  thing->index_on_path = pop.index;
}

void offset_along_path(struct s_path * path, struct s_pop * pop, float offset) {
  if (offset == 0) return;

  struct s_point h;
  h.x = pop->x;
  h.y = pop->y;
  int i = (int)floor(pop->index);
  // if (i < 0 || i >= path->num_points) { printf("poo %d(%f) of %d\n", i, pop->index, path->num_points);exit(1);}
  struct s_point * a = &path->points[i == path->num_points ? 0 : i];
  struct s_point * b = &path->points[(i == path->num_points - 1) ? 0 : i + 1];
  if (point_dist(&h, b) > offset) {
    pop->angle = atan2(b->y - a->y, b->x - a->x);
    pop->x += cos(pop->angle) * offset;
    pop->y += sin(pop->angle) * offset;
    pop->index = i + (1 - point_dist(&h, b) / point_dist(a, b));
  } else {
    offset -= point_dist(&h, b);
    pop->x = b->x;
    pop->y = b->y;
    while (offset > 0) {
      i++;
      if (i >= path->num_points) i -= path->num_points;
      a = &path->points[i];
      b = &path->points[(i == path->num_points - 1) ? 0 : i + 1];
      pop->angle = atan2(b->y - a->y, b->x - a->x);
      float d = point_dist(a, b);
      if (d > offset) {
        pop->x += cos(pop->angle) * offset;
        pop->y += sin(pop->angle) * offset;
        pop->index = i + (1 - d / point_dist(a, b));
      } else {
        pop->x = b->x;
        pop->y = b->y;
        pop->index = i + 1;
      }
      offset -= d;
    };
  }
}

struct s_actor * get_closest_actor(struct s_path * path, struct s_actor * actor) {
  struct s_actor * closest_actor = NULL;
  for (int i = 0 ; i < path->num_actors ; i++) {
    struct s_actor * actor2 = &path->actors[i];
    if (actor == actor2) continue;
    // kbfu test for loop wrapping
    if (closest_actor == NULL || fabs(actor2->index_on_path - actor->index_on_path) < fabs(closest_actor->index_on_path - actor->index_on_path)) {
      closest_actor = actor2;
    }
  }
  return closest_actor;
}

int test_if_other_actors_within(struct s_path * path, struct s_actor * actor, float distance) {
  return point_dist((struct s_point *)actor, (struct s_point *)actor->prev_actor) < distance
      || point_dist((struct s_point *)actor, (struct s_point *)actor->next_actor) < distance;
}

float index_distance(struct s_path * path, struct s_actor * a, struct s_actor * b) {
  if (b == NULL) b = a;
  return (a->index_on_path < b->index_on_path)
        ? b->index_on_path - a->index_on_path
        : path->num_points - 1 - a->index_on_path + b->index_on_path; // loop
}

float real_distance(struct s_path * path, struct s_actor * a, struct s_actor * b) {
  float ret = 0;
  int watch = 0;
  int start = floor(a->index_on_path);
  if (start != a->index_on_path) {
    ret += (point_dist(&path->points[start], &path->points[start + 1])) * (a->index_on_path - start);
    start = ceil(a->index_on_path);
  }
  // printf("start = %d\n", start);

  int stop = floor(b->index_on_path);
  if (stop != b->index_on_path) {
    ret += (point_dist(&path->points[stop], &path->points[stop + 1])) * (b->index_on_path - stop);
  }
  // printf("stop = %d\n", stop);

  for (int i = start ; i != stop ; i++) {
    ret += point_dist(&path->points[i], &path->points[i == path->num_points - 1 ? 0 : i + 1]);
    if (i == path->num_points - 1) i = -1;
    // printf("%d %d %d %f\n", i, (int)a->index_on_path, (int)b->index_on_path, ret);
    watch ++;
    if (watch > 500) { printf("oops %d %d %f\n", start, stop, ret); exit(1); }
  }

  // printf("ret = %f\n", ret);
  return ret;
}

void update_next_prev_actors(struct s_path * path) {
  for (int i = 0 ; i < path->num_actors ; i++) {
    struct s_actor * actor = &path->actors[i];
    for (int j = 0 ; j < path->num_actors ; j++) {
      struct s_actor * actor2 = &path->actors[j];
      if (i == j) continue;
      if (actor->prev_actor == NULL) actor->prev_actor = actor2;
      if (actor->next_actor == NULL) actor->next_actor = actor2;
      float d = index_distance(path, actor, actor2);
      if (d <= index_distance(path, actor, actor->next_actor)) actor->next_actor = actor2;
      if (d >= index_distance(path, actor, actor->prev_actor)) actor->prev_actor = actor2;
    }
  }
}






