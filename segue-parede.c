#include "api_robot2.h"

void main() {
	int x, y;
	x = 2;

	motor_cfg_t m1;
	m1.id = 0;
	m1.speed = 15;
	set_motor_speed(&m1);

	while (1);
}
