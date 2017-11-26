#include "api_robot2.h"

void turn_uoli();
int parou;

void _start() {
  unsigned short sonar_0;
  unsigned short sonar_1;
  unsigned short sonar_3;
  unsigned short sonar_4;
  unsigned short sonar_15;

  unsigned int time;
  motor_cfg_t m0, m1;

  m0.id = 0;
  m1.id = 1;

  m0.speed = 10;
  m1.speed = 10;
  set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);

  get_time(&time);
  add_alarm(turn_uoli, time+5);

  while(1);

}

void turn_uoli() {
  motor_cfg_t m0, m1;
  m0.id = 0;
  m1.id = 1;

  m0.speed = 30;
  m1.speed = 2;
  set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);

  return;
}
