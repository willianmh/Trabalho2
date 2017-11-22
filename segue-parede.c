#include "api_robot2.h"

void main() {
	unsigned char i;
	int ajusta;
	unsigned short distance;
	unsigned short distance_aux;
	unsigned short sonar_1;
	unsigned short sonar_14;
	motor_cfg_t m0, m1;
	
	m0.id = 0;
	m1.id = 1;
	m0.speed = 15;
	m1.speed = 15;
	set_motors_speed(&m0, &m1);
	
	// *****************************************************************
	// MODO BUSCAR-PAREDE
	// *****************************************************************
	
	// procura parede
	while (1) {
		distance = read_sonar(3);
		distance_aux = read_sonar(4);
	 	if (distance < 1000 && distance_aux < 1000) {
	 		break;	
	 	}
	}
	m0.speed = 0;
	m1.speed = 5;
	set_motor_speed(&m0);
	set_motor_speed(&m1);
	
	// vira a esquerda
	while(1) {
		distance = read_sonar(0);
		distance_aux = read_sonar(15);
		if (distance < 2000 && distance_aux < 2000){
			if (distance < distance_aux + 7 && distance > distance_aux - 7){
				m1.speed = 0;
				set_motor_speed(&m1);
				break;
			}
		}
	}
	
	// *****************************************************************
	// MODO SEGUE-PAREDE
	// *****************************************************************
	
	m0.speed = 10;
    m1.speed = 10;
    set_motors_speed(&m0, &m1);

    // ajusta a direcao do robo
    ajusta = 0;
    while (1) {
        distance     = read_sonar(0);
        sonar_1      = read_sonar(1);
        sonar_14     = read_sonar(14);
        distance_aux = read_sonar(15);
        
        //if (sonar_1 > sonar_14 + 15 && sonar_1 < 1500 && sonar_14 < 1500) {
			//if (distance > distance_aux + 10 ) {
				//m0.speed = 5;
				//m1.speed = 0;
				//set_motors_speed(&m0, &m1);
				//ajusta = 1;
			//}
		//} else if (sonar_1 < sonar_14 - 15 && sonar_1 < 1500 && sonar_14 < 1500) {
			//if (distance < distance_aux - 10 ) {
				//m0.speed = 0;
				//m1.speed = 5;
				//set_motors_speed(&m0, &m1);
				//ajusta = 1;
			//}	
		//} else {
			//if (ajusta == 1) {
				//m0.speed = 10;
				//m1.speed = 10;
				//set_motors_speed(&m0, &m1);
				//ajusta = 0;
			//}
		//}
		
        
        
        if (distance > distance_aux + 7 ) {
			m0.speed = 5;
			m1.speed = 0;
			set_motors_speed(&m0, &m1);
			ajusta = 1;
		} else if (distance < distance_aux - 7 ) {
			m0.speed = 0;
			m1.speed = 5;
			set_motors_speed(&m0, &m1);
			ajusta = 1;
		} else {
			if (ajusta == 1) {
				m0.speed = 10;
				m1.speed = 10;
				set_motors_speed(&m0, &m1);
				ajusta = 0;
			}
		}
	}

	while (1);
	int a = read_sonar(3);
	int b = read_sonar(3);
	int c = read_sonar(3);
	while (1);
}


















