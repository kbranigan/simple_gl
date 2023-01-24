
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "point_on_path.h"

int num_paths = 0;
struct s_path ** paths = NULL;

struct s_pop copy_pop(struct s_thing * t) {
  struct s_pop p;
  p.x = t->p.x;
  p.y = t->p.y;
  p.index = t->p.index;
  p.angle = t->p.angle;
  return p;
}

struct s_path * add_new_path(int num_points) {
  num_paths ++;
  paths = (struct s_path **)realloc((void *)paths, sizeof(struct s_path *) * num_paths);
  paths[num_paths - 1] = (struct s_path *)malloc(sizeof(struct s_path));
  struct s_path * path = paths[num_paths - 1];
  path->num_points = num_points;
  path->points = (struct s_point *)malloc(sizeof(struct s_point) * path->num_points);

  // path->num_actors = 0;
  // path->actors = NULL;

  path->num_things = 0;
  path->things = NULL;

  // path->num_next_paths = 0;
  // path->next_paths = NULL;
  return path;
};

void add_path_point(struct s_path * path, float x, float y) {
  path->num_points++;
  path->points = (struct s_point *)realloc(path->points, sizeof(struct s_point) * path->num_points);
  path->points[path->num_points-1].x = x;
  path->points[path->num_points-1].y = y;
}

void add_thing_to_actor_route(struct s_actor * actor, struct s_thing * thing) {
  actor->num_route_things++;
  actor->route_things = (struct s_thing **)realloc((void *)actor->route_things, sizeof(struct s_thing *) * actor->num_route_things);
  actor->route_things[actor->num_route_things - 1] = thing;
}

struct s_actor * add_new_actor_on_path(struct s_path * path, float x, float y, float max_velocity, float max_acceleration) {
  // max_velocity = 3000; // kbfu
  // max_acceleration = max_velocity * 0.25;

  path->num_things ++;
  path->things = (struct s_thing**)realloc((void *)path->things, sizeof(struct s_thing *) * path->num_things);
  struct s_actor * actor = (struct s_actor *)malloc(sizeof(struct s_actor));
  path->things[path->num_things - 1] = (struct s_thing *)actor;
  actor->type = ACTOR;
  actor->p.x = x;
  actor->p.y = y;
  actor->on_path = path;
  move_thing_onto_its_path((struct s_thing *)actor);
  actor->num_segments = 6;
  actor->width = 3.124;
  actor->height = 23;
  actor->velocity = 0;
  actor->acceleration = 0;//max_acceleration;
  actor->max_velocity = max_velocity;
  actor->max_acceleration = max_acceleration;

  actor->route_step = 0;
  actor->route_things = NULL;
  actor->num_route_things = 0;

  // actor->velocity = actor->max_velocity;
  // actor->acceleration = 0;

  return actor;

  // path->num_actors ++;
  // path->actors = (struct s_actor *)realloc((void *)path->actors, sizeof(struct s_actor) * path->num_actors);
  // struct s_actor * actor = &path->actors[path->num_actors - 1];
  // memset(actor, 0, sizeof(struct s_actor));
  // struct s_pop p;
  // point_on_path(path, x, y, &p); //, &actor->angle, &actor->perc_on_path, NULL);
  // actor->x = p.x;
  // actor->y = p.y;
  // actor->angle = p.angle;
  // actor->index = p.index;
  // actor->on_path = path;
  // // actor->perc_on_path = 0;
  // actor->num_segments = 1;
  // actor->width = 50;
  // actor->height = 250;
  // actor->velocity = velocity;
  // actor->max_velocity = max_velocity;
  // actor->acceleration = acceleration;
  // actor->max_acceleration = max_acceleration;
  // return actor;
}

struct s_thing * add_new_stop_on_path(struct s_path * path, float x, float y) {
  path->num_things ++;
  path->things = (struct s_thing**)realloc((void *)path->things, sizeof(struct s_thing *) * path->num_things);
  struct s_thing * thing = (struct s_thing *)malloc(sizeof(struct s_thing));
  path->things[path->num_things - 1] = thing;
  thing->type = STOP;
  thing->p.x = x;
  thing->p.y = y;
  thing->on_path = path;
  move_thing_onto_its_path(thing);
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

void move_thing_onto_its_path(struct s_thing * thing) {
  if (thing == NULL || thing->on_path == NULL) { fprintf(stderr, "move_thing_onto_its_path bad input\n"); exit(1); }
  point_on_path(thing->on_path, thing->p.x, thing->p.y, &thing->p);
}

void offset_along_path(struct s_path * path, struct s_pop * pop, float offset) {
  if (offset == 0) return;

  struct s_point h;
  h.x = pop->x;
  h.y = pop->y;
  int i = (int)floor(pop->index);
  if (i < 0 || i >= path->num_points) { fprintf(stderr, "offset_along_path given a pop with a bad index (%f)\n", pop->index); exit(1); }

  if (offset < 0) {
    offset *= -1;
    struct s_point * a = &path->points[i == path->num_points ? 0 : i];
    struct s_point * b = &path->points[(i == path->num_points - 1) ? 0 : i + 1];
    if (point_dist(&h, a) > offset) {
      pop->angle = atan2(a->y - b->y, a->x - b->x);
      pop->x += cos(pop->angle) * offset;
      pop->y += sin(pop->angle) * offset;
      pop->index = i + (1 - point_dist(&h, b) / point_dist(a, b));
    } else {
      offset -= point_dist(&h, a);
      pop->x = a->x;
      pop->y = a->y;
      while (offset > 0) {
        i--;
        if (i < 0) i += path->num_points;
        a = &path->points[i];
        b = &path->points[(i == path->num_points - 1) ? 0 : i + 1];
        pop->angle = atan2(a->y - b->y, a->x - b->x);
        float d = point_dist(a, b);
        if (d > offset) {
          pop->x += cos(pop->angle) * offset;
          pop->y += sin(pop->angle) * offset;
          pop->index = i + (1 - d / point_dist(a, b));
        } else {
          pop->x = a->x;
          pop->y = a->y;
          pop->index = i + 1;
        }
        offset -= d;
      };
    }
  } else if (offset > 0) {
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
}

// int test_if_other_actors_within(struct s_path * path, struct s_actor * actor, float distance) {
//   return point_dist((struct s_point *)actor, (struct s_point *)actor->prev_actor) < distance
//       || point_dist((struct s_point *)actor, (struct s_point *)actor->next_actor) < distance;
// }

float index_distance(struct s_path * path, struct s_thing * a, struct s_thing * b) {
  if (b == NULL) b = a;
  return (a->p.index < b->p.index)
        ? b->p.index - a->p.index
        : path->num_points - 1 - a->p.index + b->p.index; // loop
}

int shit = 0;

float real_distance(struct s_path * path, struct s_thing * a, struct s_thing * b) {
  float ret = 0;
  int watch = 0;
  int start = floor(a->p.index);
  if (start != a->p.index) {
    // printf("%d %f %f %f %f\n",
    //   start,
    //   a->p.index, 
    //   point_dist(&path->points[start], &path->points[start + 1]), 
    //   (a->p.index - start),
    //   point_dist(&path->points[start], &path->points[start + 1]) * (a->p.index - start));
    // if (shit++ > 10) exit(1);
    ret += point_dist(&path->points[start], &path->points[start + 1]) * (1 - (a->p.index - start));
    start = ceil(a->p.index);
  }
  // printf("start = %f %d\n", a->p.index, start);

  int stop = floor(b->p.index);
  if (stop != b->p.index) {
    ret += point_dist(&path->points[stop], &path->points[stop + 1]) * (b->p.index - stop);
  }
  // printf("stop = %d\n", stop);

  for (int i = start ; i != stop ; i++) {
    ret += point_dist(&path->points[i], &path->points[i == path->num_points - 1 ? 0 : i + 1]);
    if (i == path->num_points - 1) i = -1;
    // printf("%d %d %d %f\n", i, (int)a->p.index, (int)b->p.index, ret);
    watch ++;
    if (watch > path->num_points * 2) { printf("oops %d %d %f\n", start, stop, ret); exit(1); }
  }

  // printf("ret = %f\n", ret);
  return ret;
}

void update_next_prev_things(struct s_path * path) {
  for (int i = 0 ; i < path->num_things ; i++) {
    struct s_thing * thing = path->things[i];
    for (int j = 0 ; j < path->num_things ; j++) {
      struct s_thing * thing2 = path->things[j];
      if (i == j) continue;
      if (thing->prev_thing == NULL) thing->prev_thing = thing2;
      if (thing->next_thing == NULL) thing->next_thing = thing2;
      float d = index_distance(path, thing, thing2);
      if (d  <= index_distance(path, thing, thing->next_thing)) thing->next_thing = thing2;
      if (d  >= index_distance(path, thing, thing->prev_thing)) thing->prev_thing = thing2;
    }
  }
}






