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
	// anda para frente
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
	// ate encontrar o uoli parar
	while (1) {
		if (parou == 1)
		break;
	}
	// gira para direita
	m1.speed = 2;
	set_motor_speed(&m1);
	set_motor_speed(&m1);
	set_motor_speed(&m1);
	// deixa a parede a esquerda
	while (1) {
		// sonares laterais esquerdos
		sonar_0 = read_sonar(0);
		sonar_15 = read_sonar(15);
		// proximidade: sonar_0 e sonar_15 < 1000
		// coerencia:   sonar_0 = sonar_15 +- 200 (range)
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
		sonar_1 = read_sonar(1);

		// diferentes niveis de proximidade
		if (sonar_1 < 200) {
			// muito proximo a parede -> curva rapida para esquerda
			m0.speed = 0;
			m1.speed = 10;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		} else if (sonar_1 < 500) {
			// perto da parede -> curva para esquerda
			m0.speed = 0;
			m1.speed = 7;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);

		} else if (sonar_1 < 900) {
			// ajusta de alinhamento -> curva leve p/ esquerda
			m0.speed = 3;
			m1.speed = 7;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		} else if (sonar_1 > 1700) {
			// se sonar_1 for muito distance, le outro sonar para
			// verificar o contexto do uoli
			sonar_0 = read_sonar(0);
			if (sonar_0 < 1000) {
				// perto de uma ponta -> curva muito leve
				m0.speed = 7;
				m1.speed = 5;
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
			} else {
				// curva para direita
				m0.speed = 7;
				m1.speed = 3;
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
				set_motors_speed(&m0, &m1);
			}
		} else if (sonar_1 > 1170) {
			// ajusta o alinhamento, curva leve para direita
			m0.speed = 7;
			m1.speed = 3;
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
			set_motors_speed(&m0, &m1);
		} else {
			// se esta alinhado, para frente
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

// callback
void stop_uoli (){
	// flag para ativar a callback
    if (parou == 0) {
	    m0.id = 0;
	    m1.id = 1;

	    m0.speed = 0;
	    m1.speed = 0;
	    set_motors_speed(&m0, &m1);
	    set_motors_speed(&m0, &m1);
	    set_motors_speed(&m0, &m1);
	    set_motors_speed(&m0, &m1);
		// desabilita callbacks desse tipo
		parou = 1;
	}
    return;
};
