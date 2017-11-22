#include "api_robot2.h"

void main() {
	unsigned char i;
	int x;
	unsigned short distance;
	unsigned short distance_aux;
	motor_cfg_t m0, m1;
	m0.id = 0;
	m1.id = 1;
	
	m0.speed = 20;
	m1.speed = 20;
	set_motors_speed(&m0, &m1);
	
	// *****************************************************************
	// MODO BUSCAR-PAREDE
	// *****************************************************************
	
	// procura parede
	while (1) {
		distance = read_sonar(3);
		distance_aux = read_sonar(4);
	 	if (distance < 950 && distance_aux < 950) {
	 		m0.speed = 0;
	 		m1.speed = 0;
	 		set_motor_speed(&m0);
	 		set_motor_speed(&m1);
	 		break;	
	 	}
	}
	
	// vira a esquerda
	m1.speed = 5;
	set_motor_speed(&m1);
	while(1) {
		distance = read_sonar(0);
		distance_aux = read_sonar(15);
		
		if (distance < distance_aux + 7 && distance > distance_aux - 7){
			m1.speed = 0;
			set_motor_speed(&m1);
			break;
		}
	}
	
	// *****************************************************************
	// MODO SEGUE-PAREDE
	// *****************************************************************
	
	
	
	while (1);
	int a = read_sonar(3);
	int b = read_sonar(3);
	int c = read_sonar(3);
	while (1);
}

