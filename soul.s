.org 0x0
.section .iv,"a"

_start:
@ ****************************************************************************
@ Vetor de interrupcoes do sistema
@ ****************************************************************************
interrupt_vector:
	b RESET_HANDLER
.org 0x8
	b SOFTWARE_INT_HANDLER
.org 0x18
	b IRQ_HANDLER


.text
.org 0x100

.set GPT_CR,   0x53FA0000
.set GPT_PR,   0x53FA0004
.set GPT_SR,   0x53FA0008
.set GPT_IR,   0x53FA000C
.set GPT_OCR1, 0x53FA0010
.set GPT_OCR2, 0x53FA0014

@ ciclos do GPT
.set TIME_SZ,  100

@ endereco porta GPIO
.set DR,       0x53F84000
.set GDIR,     0x53F84004
.set PSR,      0x53F84008

.set MAX_ALARMS,    8
.set MAX_CALLBACKS, 8

@ inicio da funcaio do usuario
.set START,	   0x77812000
@ ****************************************************************************
@ Reset do sistema
@ ****************************************************************************
RESET_HANDLER:
	@ Zera o Tempo do sistema
	ldr r2, =SYSTEM_TIME		@ carrega o endereco
	mov r0, #0					@ r0 <- #0
	str r0, [r2]				@ guarda '0' no endereco

	@Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
	ldr r0, =interrupt_vector
	mcr p15, 0, r0, c12, c0, 0

	ldr r0, =GPT_CR
	mov r1, #0x00000041
	str r1, [r0]

	ldr r0, =GPT_PR
	mov r1, #0x00000000
	str r1, [r0]

	ldr r0, =GPT_OCR1
	mov r1, #TIME_SZ
	str r1,[r0]

	ldr r0, =GPT_IR
	mov r1, #1
	str r1, [r0]

	@ Configura entrada/saida GPIO
	ldr r0, =GDIR
	ldr r1, =0xfffc003e
	str r1, [r0]

	@ zera o numero de callbacks ativas
	ldr r0, =ACTIVED_CALLBACKS
	mov r1, #0
	str r1, [r0]

	@ zera o numero de alarmes ativos
	ldr r0, =ACTIVED_ALARMS
	mov r1, #0
	str r1, [r0]

SET_TZIC:
	@ Constantes para os enderecos do TZIC
	.set TZIC_BASE,             0x0FFFC000
	.set TZIC_INTCTRL,          0x0
	.set TZIC_INTSEC1,          0x84
	.set TZIC_ENSET1,           0x104
	.set TZIC_PRIOMASK,         0xC
	.set TZIC_PRIORITY9,        0x424

	@ Liga o controlador de interrupcoes
	@ R1 <= TZIC_BASE

	ldr	r1, =TZIC_BASE

	@ Configura interrupcao 39 do GPT como nao segura
	mov	r0, #(1 << 7)
	str	r0, [r1, #TZIC_INTSEC1]

	@ Habilita interrupcao 39 (GPT)
	@ reg1 bit 7 (gpt)

	mov	r0, #(1 << 7)
	str	r0, [r1, #TZIC_ENSET1]

	@ Configure interrupt39 priority as 1
	@ reg9, byte 3

	ldr r0, [r1, #TZIC_PRIORITY9]
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

	@ Configure PRIOMASK as 0
	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]

	@ Habilita o controlador de interrupcoes
	mov	r0, #1
	str	r0, [r1, #TZIC_INTCTRL]

	@ Configura as pilhas

	@instrucao msr - habilita interrupcoes
	msr CPSR_c, #0x13			@ modo supervisor
	ldr sp, =STACK_SUPERVISOR
	msr CPSR_c, #0x12			@ modo IRQ
	ldr sp, =STACK_IRQ
	msr CPSR_c, #0x10       	@ User mode, IRQ/FIQ enabled
	ldr sp, =STACK_USER

	@ inicio do programa do usuario
	ldr pc, =START

@ ****************************************************************************
@ Tratador de SVC
@  parametro svc:  r7 (codigo da syscall)
@  retorno da svc: r0
@ ****************************************************************************

@ vetor de interrupções
SOFTWARE_INT_HANDLER:
	push {r4-r6, r8, lr}
	cmp r7, #16
	beq svc_read_sonar
	cmp r7, #17
	beq svc_register_proximity_callback
	cmp r7, #18
	beq svc_set_motor_speed
	cmp r7, #19
	beq svc_set_motors_speed
	cmp r7, #20
	beq svc_get_time
	cmp r7, #21
	beq svc_set_time
	cmp r7, #22
	beq svc_set_alarm
	cmp r7, #23
	beq svc_irq_mode_callback
	cmp r7, #24
	beq svc_irq_mode_alarm
	@ valor invalido de r7
	b SOFTWARE_INT_HANDLER_ERROR
@ ******************************
@ tratador svc read_sonar
@ parametro : r0 = Id sonar
@ retorno :	  r0 = distace lida
@ ******************************
svc_read_sonar:
	@ valor valido r0
	cmp r0, #15
	bhi svc_read_sonar_error @ coloca -1

	@ seleciona o sensor (mux) e trigger = 0
	mov r1, #0xffffffc1 	@ mascara 1100 0001
	orr r0, r1, r0, lsl #2 	@ ajusta a posicao dos dados e trigger em '0'
	@ r0 -> sensor na posicão 5:2 e trigger em '0' e resto em '1'

	ldr r1, =DR         @ r1 <- endereco DR
	str r0, [r1]		@ guarda o sonar a ser lido

	@ delay 1
	mov r2, #200
	delay_1: @ rotulo do loop
	sub r2,r2, #1
	cmp r2, #0
	bne delay_1
	@ coloca trigger em '1'
	ldr r0, [r1]
	orr r0, r0, #2
	str r0, [r1]
	@ delay 2
	mov r2, #200
	delay_2: @ rotulo do loop
	sub r2,r2, #1
	cmp r2, #0
	bne delay_2
	@ coloca trigger em '0'
	mov r2, #0xfffffffd
	ldr r0, [r1]
	and r0, r0, r2
	str r0, [r1]

	@ espera pela flag
	ldr r2, =DR
	espera_flag: @ rotulo do loop
	ldr r0, [r2]		@ carrega o conteudo inteiro
	and r0, r0, #1      @ carrega flag em r0
	cmp r0, #1
	bne espera_flag

	@ GPIO pronta para ser lida
	ldr r0, [r2]		@ carrega os dados de [DR]
	mov r0, r0, lsr #6  @ ajusta a posicao de SONAR_DATA
	ldr r1, =0x00000fff @ mascara
	and r0, r0, r1      @ ignora o resto, deixa apenas [11:0]
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc register_proximity_callback
@ parametro : r0 = Id sonar
@			  r1 = Limiar distancia
@			  r2 = ponteiro da funcao
@ ******************************
svc_register_proximity_callback:
	@ verifica max de callbacks ativas
	ldr r4, =ACTIVED_CALLBACKS	@ carrega o endereco
	ldr r5, [r4]				@ r5 = num callbacks ativas
	cmp r5, #MAX_CALLBACKS		@ compara com o MAX
	bhs too_many_callbacks
	@ verifica o Id sonar
	cmp r0, #15
	bhi svc_register_proximity_callback_id_invalid
	@ aux para armazenar (o tamanho dos dados é de 4 bytes)
	mov r6, #4
	mul r6, r5, r6
	@ registra a CALLBACK
	ldr r3, =CALLBACK_SONAR_BASE 		@ end do vetor de Id's
	str r0, [r3, r6]					@ salva
	ldr r3, =CALLBACK_THRESHOLD_BASE	@ end do vetor de Limiar
	str r1, [r3, r6]					@ salva
	ldr r3, =CALLBACK_FUNCTION_BASE		@ end do vetor de funcoes
	str r2, [r3, r6]
	@ incrementa o num de CALLBACKS
	add r5, r5, #1
	str r5, [r4]

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc set_motor_speed
@ parametro : r0 = Id sonar
@			  r1 = Velocidade
@ ******************************
svc_set_motor_speed:
	@ verifica velocidade
	cmp r1, #63
	bhi svc_set_motor_speed_velocity_invalid
	@ verifica Id do motor
	cmp r0, #1
	bhi svc_set_motor_speed_id_invalid

	@ habilita w1, copia motor1_speed e desabilita trigger
	set_motor_r1: @ rotulo de identificacao
	moveq r1, r1, lsl #26	@ ajusta a posicao dos dados
	ldreq r2, =0x01fffffd	@ mascara

	@ habilita w0, copia motor0_speed e desabilita trigger
	set_motor_r0: @ rotulo de identificacao
	movne r1, r1, lsl #19	@ ajusta a posicao dos dados
	ldrne r2, =0xfe03fffd	@ mascara

	@ junta e guarda
	orr r1, r1, r2
	ldr r0, =DR				@ endereco
	str r1, [r0]			@ guarda o valor

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc set_motors_speed
@ parametro : r0 = velocidade motor 0
@			  r1 = velocidade motor 1
@ ******************************
svc_set_motors_speed:
	@ verifica velocidade motor 0
	cmp r0, #63
	bhi svc_set_motor_speed_id_invalid
	@ verifica velocidade motor 1
	cmp r1, #63
	bhi svc_set_motor_speed_velocity_invalid
	@ ajusta a posicao dos dados
	mov r0, r0, lsl #19				@ desloca r0 p/ posicao das flags motor 0
	mov r1, r1, lsl #26				@ desloca r1 p/ posicao das flags motor 1
	@ mascaras
	mov r2, #0x01f80000
	and r0, r0, r2					@ deixa só o desejado
	mov r2, #0xfc000000
	and r1, r1, r2					@ deixa só o desejado

	orr r0, r0, r1					@ junta as informacoes em r0
	@ w0 e w1, motor0 e motor1 e trigger em '0'
	ldr r2, =0x0003fffd
	orr r0, r0, r2
	@ envia a informacao
	ldr r1, =DR
	str r0, [r1]					@ escreve em DR

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc get_time
@ retorno : r0 = system time
@ ******************************
svc_get_time:
	ldr r0, =SYSTEM_TIME		@ carrega o endereco do SYSTEM_TIME
	ldr r0, [r0]				@ carrega o dado do endereco
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc set_time
@ parametro : r0 = system time
@ ******************************
svc_set_time:
	ldr r1, =SYSTEM_TIME		@ carrega o endereco do SYSTEM_TIME
	str r0, [r1]				@ salva o valor de r0 no endereco
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc get_time
@ parametro : r0 = function
@			  r1 = system time
@ ******************************
svc_set_alarm:
	@ verifica alarmes ativos
	ldr r4, =ACTIVED_ALARMS		@ carrega o endereco
	ldr r5, [r4]				@ r5 = num de alarmes ativos
	cmp r5, #MAX_ALARMS			@ compara
	bhs svc_too_many_alarms
	@ verifica se o tempo é valido
	ldr r6, =SYSTEM_TIME
	ldr r6, [r6]				@ carrega o tempo atual
	cmp r1, r6					@ compara com r1
	bls svc_time_invalid
	@ auxiliar (tamanho do dado e 4 bytes)
	mov r6, #4
	mul r6, r5, r6
	@ salva o alarme
	ldr r3, =ALARM_FUNCTION_BASE @ end do vetor
	str r0, [r3, r6]			 @ salva
	ldr r3, =ALARM_TIME_BASE	 @ end do vetor
	str r1, [r3, r6]			 @ salva
	@ incrementa o num de alarmes
	add r5, r5, #1
	str r5, [r4]

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ tratador svc auxiliares
@ ambas as svc's retornam o modo para IRQ apos ter chamado a funcao do usuario no IRQ handler
@ ******************************
svc_irq_mode_callback:
	pop {r4-r6, r8, lr}
	msr CPSR_c, #0x12
	b irq_callback
svc_irq_mode_alarm:
	pop {r4-r6, r8, lr}
	msr CPSR_c, #0x12
	b irq_alarm

@ ******************************
@ retorno : r0 = -1
@ ******************************
svc_read_sonar_error:
too_many_callbacks:
svc_set_motor_speed_id_invalid:
svc_too_many_alarms:
	mov r0, #0
	sub r0, r0, #1
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ retorno : r0 = -2
@ ******************************
svc_register_proximity_callback_id_invalid:
svc_set_motor_speed_velocity_invalid:
svc_time_invalid:
	mov r0, #0
	sub r0, r0, #2
	b SOFTWARE_INT_HANDLER_END
@ ******************************
@ retorno : r0 = 0
@ ******************************
SOFTWARE_INT_HANDLER_END:
	pop {r4-r6, r8, lr}
	movs pc, lr

SOFTWARE_INT_HANDLER_ERROR:

@ ****************************************************************************
@ Tratador de IRQ
@ ****************************************************************************
IRQ_HANDLER:
	push {r0-r8, lr}
	@ Configura GPT
	ldr r0, =GPT_SR
	mov r1, #0x1
	str r1, [r0]
	@ incrementa o system time
	ldr r0, =SYSTEM_TIME
	ldr r1, [r0]
	add r1, r1, #1
	str r1, [r0]
@ *******************************************************************
@	Verifica Callbacks
@	Remove e chama funcao
@ *******************************************************************
	ldr r0, =ACTIVED_CALLBACKS
	mov r1, #0                        @ r1 = i

	verify_callbacks:
	ldr r8, [r0]                      @ r8 = actived callbacks
	cmp r1, r8                        @ while i < callbacks_actived
	beq verify_callbacks_end

	@ registrador aux (4 bytes)
	mov r6, #4
	mul r6, r1, r6

	ldr r5, =CALLBACK_SONAR_BASE
	@ *****************************************************************
   	@ chamada de sistema p/ leitura do sonar
   	@ *****************************************************************
	push {r0-r3}
	ldr r0, [r5, r6]              @ carrega o Id do sonar
	mov r7, #16                   @ escolhe a syscall read_sonar
	svc #0
	mov r7, r0                    @ retorno da funcao em R7
	pop {r0-r3}

	ldr r5, =CALLBACK_THRESHOLD_BASE
	ldr r2, [r5, r6]              @ carrega o limiar
	cmp r7, r2                    @ if (distancia < limiar)
	bhs next_callback

	ldr r5, =CALLBACK_FUNCTION_BASE
	ldr r7, [r5, r6]                @ r7 <- function a ser chamada

	@ *****************************************************************
	@ apagar a callback
	@ *****************************************************************
	@ decrementa callbacks ativas
	sub r8, r8, #1
	str r8, [r0]
	@ laco
	mov r2, r1                    @ R2 = j = num_callback
	remove_callback:
	cmp r2, r8
	beq remove_callback_end       @ while j < callbacks - 1
	@ rotaciona o vetor
	ldr r4, =CALLBACK_SONAR_BASE
	add r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	ldr r3, [r4, r6]              @ carrega sonar[j+1]
	sub r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	str r3, [r4, r6]              @ salva em sonar[j]
	@ rotaciona o vetor
	ldr r4, =CALLBACK_THRESHOLD_BASE
	add r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	ldr r3, [r4, r6]              @ carrega threshold[j+1]
	sub r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	str r3, [r4, r6]              @ salva em threshold[j]
	@ rotaciona o vetor
	ldr r4, =CALLBACK_FUNCTION_BASE
	add r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	ldr r3, [r4, r6]              @ carrega threshold[j+1]
	sub r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	str r3, [r4, r6]              @ salva em threshold[j]

	add r2, r2, #1                @ j++
	b remove_callback
	remove_callback_end:

	mov r1, #0					  @ ajusta
	@ *****************************************************************
	@ executa a funcao do usuario
	@ *****************************************************************
	push {r0-r3}
	msr CPSR_c, #0x10			@ modo usuario
	blx r7
	mov r7, #23					@ recupera modo irq
	svc 0x0
	irq_callback:
	pop {r0-r3}

	next_callback:
	add r1, r1, #1              @ i++
	b verify_callbacks
	verify_callbacks_end: @ fim

@ *******************************************************************
@	Verifica Alarmes
@	Remove e chama funcao
@ *******************************************************************
	ldr r0, =ACTIVED_ALARMS
	mov r1, #0							@ r1 = i

	verify_alarm:
	ldr r8, [r0]						@ r8 = num de alarmes
	cmp r1, r8							@ while i < alarmes
	beq verify_alarm_end
	@ registrador aux (4 bytes)
	mov r6, #4
	mul r6, r1, r6

	ldr r5, =ALARM_TIME_BASE

	@ carrega o tempo do sistema e compara com alarme
	ldr r7, =SYSTEM_TIME
	ldr r7, [r7]
	ldr r2, [r5, r6]			@ carrega o tempo do alarme
	cmp r2, r7					@ compara alarme com sys time
	bhi next_alarm
	@ carrega a funcao a ser chamada
	ldr r5, =ALARM_FUNCTION_BASE
	ldr r7, [r5, r6]
	@ *****************************************************************
	@ apagar o alarme
	@ *****************************************************************
	@ decrementa o num de alarmes
	sub r8, r8, #1
	str r8, [r0]
	@ laco
	mov r2, r1
	remove_alarm:
	cmp r2, r8
	beq remove_alarm_end
	@ rotaciona o vetor
	ldr r4, =ALARM_TIME_BASE
	add r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	ldr r3, [r4, r6]				@ carrega o tempo[j+1]
	sub r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	str r3, [r4, r6]				@ salva em tempo[j]
	@ rotaciona o vetor
	ldr r4, =ALARM_FUNCTION_BASE
	add r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	ldr r3, [r4, r6]				@ carrega function[j+1]
	sub r2, r2, #1
	mov r6, #4
	mul r6, r2, r6
	str r3, [r4, r6]				@ salva em function[j]

	add r2, r2, #1
	b remove_alarm
remove_alarm_end:
	mov r1, #0				@ ajusta
	@ *****************************************************************
	@ executa a funcao do usuario
	@ *****************************************************************
	push {r0-r3}
	msr CPSR_c, #0x10		@ modo usuario
	blx r7
	mov r7, #24				@ recupera modo irq
	svc 0x0
	irq_alarm:
	pop {r0-r3}

	next_alarm:
	add r1, r1, #1			@ i++
	b verify_alarm
	verify_alarm_end: @ fim

	@ fim do tratador IRQ
	pop {r0-r8, lr}
	sub lr, lr, #4
	movs pc, lr

@ ****************************************************************************
@ secao de dados
@ ****************************************************************************
.data
	SYSTEM_TIME: .skip 4

	ACTIVED_CALLBACKS:    .skip 4
	ACTIVED_ALARMS:		  .skip 4

@ registro das callbacks
CALLBACK_SONAR_BASE:
	CALLBACK_0_SONAR:		.skip 4
	CALLBACK_1_SONAR:		.skip 4
	CALLBACK_2_SONAR:		.skip 4
	CALLBACK_3_SONAR:		.skip 4
	CALLBACK_4_SONAR:		.skip 4
	CALLBACK_5_SONAR:		.skip 4
	CALLBACK_6_SONAR:		.skip 4
	CALLBACK_7_SONAR:		.skip 4

CALLBACK_FUNCTION_BASE:
	CALLBACK_0_FUNCTION:	.skip 4
	CALLBACK_1_FUNCTION:	.skip 4
	CALLBACK_2_FUNCTION:	.skip 4
	CALLBACK_3_FUNCTION:	.skip 4
	CALLBACK_4_FUNCTION:	.skip 4
	CALLBACK_5_FUNCTION:	.skip 4
	CALLBACK_6_FUNCTION:	.skip 4
	CALLBACK_7_FUNCTION:	.skip 4

CALLBACK_THRESHOLD_BASE:
	CALLBACK_0_THRESHOLD:	.skip 4
	CALLBACK_1_THRESHOLD:	.skip 4
	CALLBACK_2_THRESHOLD:	.skip 4
	CALLBACK_3_THRESHOLD:	.skip 4
	CALLBACK_4_THRESHOLD:	.skip 4
	CALLBACK_5_THRESHOLD:	.skip 4
	CALLBACK_6_THRESHOLD:	.skip 4
	CALLBACK_7_THRESHOLD:	.skip 4

@ registro dos alarmes
ALARM_TIME_BASE:
	ALARM_0_TIME:			.skip 4
	ALARM_1_TIME:			.skip 4
	ALARM_2_TIME:			.skip 4
	ALARM_3_TIME:			.skip 4
	ALARM_4_TIME:			.skip 4
	ALARM_5_TIME:			.skip 4
	ALARM_6_TIME:			.skip 4
	ALARM_7_TIME:			.skip 4

ALARM_FUNCTION_BASE:
	ALARM_0_FUNCTION:		.skip 4
	ALARM_1_FUNCTION:		.skip 4
	ALARM_2_FUNCTION:		.skip 4
	ALARM_3_FUNCTION:		.skip 4
	ALARM_4_FUNCTION:		.skip 4
	ALARM_5_FUNCTION:		.skip 4
	ALARM_6_FUNCTION:		.skip 4
	ALARM_7_FUNCTION:		.skip 4


@ pilhas
	.skip 1000
STACK_USER:
	.skip 1000
STACK_SUPERVISOR:
	.skip 1000
STACK_IRQ:
