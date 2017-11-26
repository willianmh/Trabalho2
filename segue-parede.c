#include "api_robot2.h"

void stop_uoli();
int parou;
motor_cfg_t m0, m1;

void _start() {
	unsigned short sonar_0;
	unsigned short sonar_1;
	unsigned short sonar_3;
	unsigned short sonar_4;
	unsigned short sonar_15;

	// *****************************************************************
	// MODO BUSCAR-PAREDE
	// *****************************************************************
	// procura parede
	m0.id = 0;
	m1.id = 1;
	m0.speed = 18;
	m1.speed = 18;

	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);

	parou = 0;
  register_proximity_callback(3, 900, stop_uoli);
	register_proximity_callback(4, 900, stop_uoli);

	while (1) {
		if (parou == 1)
		break;
	}
	m1.speed = 2;
	set_motor_speed(&m1);
	set_motor_speed(&m1);
	set_motor_speed(&m1);

	while (1) {
		sonar_0 = read_sonar(0);
		sonar_15 = read_sonar(15);
		if (sonar_0 < 1000 && sonar_15 < 1000 && sonar_0 < sonar_15 + 200 && sonar_0 > sonar_15 - 200) {
			m1.speed = 0;
			set_motor_speed(&m1);
			set_motor_speed(&m1);
			break;
		}
	}


	// *****************************************************************
	// MODO SEGUE-PAREDE
	// *****************************************************************

	m0.speed = 7;
  m1.speed = 7;
  set_motors_speed(&m0, &m1);

	while (1) {
		/* code */
		sonar_1 		= read_sonar(1);
		if (sonar_1 < 200) {
			m0.speed = 0;
			m1.speed = 10;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		} else if (sonar_1 < 500) {
			m0.speed = 0;
			m1.speed = 7;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);

		} else if (sonar_1 < 900) {
			m0.speed = 3;
			m1.speed = 7;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		} else if (sonar_1 > 1700) {
			sonar_0 = read_sonar(0);
			if (sonar_0 < 1000) {
				m0.speed = 7;
				m1.speed = 5;
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
			} else {
				m0.speed = 7;
				m1.speed = 3;
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
			}
		} else if (sonar_1 > 1170) {
			m0.speed = 7;
			m1.speed = 3;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		} else {
			m0.speed = 8;
			m1.speed = 8;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		}

	}

	while (1);

	return;
}

void stop_uoli (){
    if (parou == 0) {
	    m0.id = 0;
	    m1.id = 1;

	    m0.speed = 0;
	    m1.speed = 0;
	    set_motors_speed(&m0, &m1);
	    set_motors_speed(&m0, &m1);
	    set_motors_speed(&m0, &m1);
	    set_motors_speed(&m0, &m1);

			parou = 1;
		}
    return;
};
