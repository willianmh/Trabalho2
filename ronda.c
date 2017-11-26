#include "api_robot2.h"

void turn_right_3();
void turn_right_4();
void turn_90();
void go_ahead();


motor_cfg_t m0, m1;
unsigned int sys_time;

void _start() {
  unsigned short sonar_0;
  unsigned short sonar_1;
  unsigned short sonar_3;
  unsigned short sonar_4;
  unsigned short sonar_15;
  m0.id = 0;
  m1.id = 1;

  sys_time = 1;
  register_proximity_callback(3, 900, turn_right_3);
  register_proximity_callback(4, 900, turn_right_4);

  go_ahead();

  while(1);

  return;
}

void turn_right_3() {
  unsigned short sonar_1;

  m0.id = 0;
  m1.id = 1;

  m0.speed = 0;
  m1.speed = 15;
  set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);

  while (1) {
    sonar_1 = read_sonar(1);
    if(sonar_1 > 600)
      break;
  }

  m0.speed = 10;
  m1.speed = 10;
  set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);

  register_proximity_callback(3, 900, turn_right_3);
  return;
}

void turn_right_4() {
  unsigned short sonar_1;
  m0.id = 0;
  m1.id = 1;

  m0.speed = 0;
  m1.speed = 15;
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);

  while (1) {
    sonar_1 = read_sonar(1);
    if(sonar_1 > 600)
      break;
  }

  m0.speed = 10;
  m1.speed = 10;
  set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);


  register_proximity_callback(3, 900, turn_right_4);

  return;
}

void turn_90() {
  m0.speed = 0;
  m1.speed = 37;

  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);

  if(sys_time >= 50)
    sys_time = 1;
  else
    sys_time++;

  set_time(0);
  add_alarm(go_ahead, 1);
  return;
}

void go_ahead() {
  m0.speed = 10;
  m1.speed = 10;

  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);
  set_motors_speed(&m0, &m1);

  set_time(0);
  add_alarm(turn_90, sys_time);
  return;
}
