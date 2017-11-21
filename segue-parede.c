#include "api_robot2.h"

void main() {
	// unsigned char i;
	// int x;
	// unsigned short distance;
	//
	// motor_cfg_t m0, m1;
	// m0.id = 0;
	// m1.id = 1;
	//
	// m0.speed = 15;
	// m1.speed = 15;
	// set_motors_speed(&m0, &m1);
	// while (1) {
	// 	distance = read_sonar(3);
	// 	if (distance < 1200) {
	// 		m0.speed = 0;
	// 		m1.speed = 0;
	// 		set_motor_speed(&m0);
	// 		set_motor_speed(&m1);
	// 		break;
	// 	}
	// }
	//
	// while (1);
	int a = read_sonar(3);
	int b = read_sonar(3);
	int c = read_sonar(3);
	while (1);
}
