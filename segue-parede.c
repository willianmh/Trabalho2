#include "api_robot2.h"

void stop_uoli();
int parou;

void _start() {
	unsigned char i;
	int ajusta;
	unsigned short distance;
	unsigned short distance_aux;
	unsigned short sonar_1;
	unsigned short sonar_14;
	unsigned int x, y;
	motor_cfg_t m0, m1;

	// *****************************************************************
	// MODO BUSCAR-PAREDE
	// *****************************************************************
	// procura parede
	m0.id = 0;
	m1.id = 1;
	m0.speed = 15;
	m1.speed = 15;
	
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	set_motors_speed(&m0, &m1);
	
	
	parou = 0;
    register_proximity_callback(3, 800, stop_uoli);
	
	// vira a esquerda
	while(1) {
		if(parou == 1) {
			
			distance = read_sonar(0);
			distance = read_sonar(0);
			distance = read_sonar(0);
			distance_aux = read_sonar(15);
			distance_aux = read_sonar(15);
			distance_aux = read_sonar(15);
			if (distance < 1000 && distance_aux < 1000) {
				m1.speed = 0;
				set_motor_speed(&m1);
				set_motor_speed(&m1);
				break;
			}
		}
	}

	// *****************************************************************
	// MODO SEGUE-PAREDE
	// *****************************************************************

	m0.speed = 7;
    m1.speed = 7;
    set_motors_speed(&m0, &m1);

    // ajusta a direcao do robo
    ajusta = 0;
    while (1) {
        distance     = read_sonar(0);
        distance     = read_sonar(0);
        //sonar_1      = read_sonar(1);
        //sonar_1      = read_sonar(1);
        //sonar_14     = read_sonar(14);
        //sonar_14     = read_sonar(14);
        distance_aux = read_sonar(15);
        distance_aux = read_sonar(15);


        if ( (sonar_1 < sonar_14 + 450 && sonar_1 > sonar_14 - 450) && (distance < 900 || distance_aux < 900)) {
            // reto
            m0.speed = 4;
            m1.speed = 4;
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            ajusta = 0;
        } else if((distance < distance_aux - 10) || (sonar_1 < sonar_14 - 400 && sonar_14 < 1700)) {

            // direita
            m0.speed = 1;
            m1.speed = 4;
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);

            ajusta = 1;
        } else if((distance > distance_aux + 10) || (sonar_1 > sonar_14 + 400 && sonar_1 < 1700)) {
            // esquerda
            m0.speed = 4;
            m1.speed = 1;
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);
            set_motors_speed(&m0, &m1);

            ajusta = 1;
        } else {
            if (ajusta == 1) {
                m0.speed = 7;
                m1.speed = 7;
                set_motors_speed(&m0, &m1);
                set_motors_speed(&m0, &m1);
                set_motors_speed(&m0, &m1);
                set_motors_speed(&m0, &m1);
                ajusta = 0;
            }
        }


		

        //if ((sonar_1 > sonar_14 + 50 && sonar_1 < 1500 && sonar_14 < 1500) || (distance > distance_aux + 10 ) || (sonar_1 > 2100 && distance > 1000)) {			
			//// esquerda
			//m0.speed = 5;
			//m1.speed = 2;
			//set_motors_speed(&m0, &m1);
			//set_motors_speed(&m0, &m1);
			//set_motors_speed(&m0, &m1);
			//set_motors_speed(&m0, &m1);


			//ajusta = 1;
			
		//} else if ((sonar_1 < sonar_14 - 50 && sonar_1 < 1500 && sonar_14 < 1500)||(distance < distance_aux - 10 ) || (sonar_14  > 2100 && distance_aux > 1000)) {			
			//// direita
			//m0.speed = 2;
			//m1.speed = 5;
			//set_motors_speed(&m0, &m1);
			//set_motors_speed(&m0, &m1);
			//set_motors_speed(&m0, &m1);
			//set_motors_speed(&m0, &m1);

			//ajusta = 1;
			
		//} else {
			//if (ajusta == 1) {
				//m0.speed = 7;
				//m1.speed = 7;
				//set_motors_speed(&m0, &m1);
				//set_motors_speed(&m0, &m1);
				//set_motors_speed(&m0, &m1);
				//set_motors_speed(&m0, &m1);

				//ajusta = 0;
			//}
		//}

//		if (distance > distance_aux + 5 || distance > 950) {
//			// gira para esquerda
//			m0.speed = 4;
//			m1.speed = 1;
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			ajusta = 1;
//		} else if (distance < distance_aux - 5 || distance < 300) {
//			// gira para direita
//			m0.speed = 1;
//			m1.speed = 4;
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			ajusta = 1;
//		} else if (ajusta == 1) {
//			m0.speed = 6;
//			m1.speed = 6;
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			set_motors_speed(&m0, &m1);
//			ajusta = 0;
//		}

	}

	while (1);
	int a = read_sonar(3);
	int b = read_sonar(3);
	int c = read_sonar(3);
	while (1);
}

void stop_uoli (){
    motor_cfg_t m0, m1;
    m0.id = 0;
    m1.id = 1;

    m0.speed = 0;
    m1.speed = 3;
    set_motors_speed(&m0, &m1);
    set_motors_speed(&m0, &m1);
    set_motors_speed(&m0, &m1);
    
    parou = 1;

    return;
};
