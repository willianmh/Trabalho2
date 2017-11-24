.org 0x0
.section .iv,"a"

_start:
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

.set TIME_SZ,  100

.set DR,       0x53F84000
.set GDIR,     0x53F84004
.set PSR,      0x53F84008

.set MAX_ALARMS,    8
.set MAX_CALLBACKS, 8

.set START,	   0x77812000

RESET_HANDLER:
	@ Zera o Tempo do sistema
	ldr r2, =CONTADOR  @lembre-se de declarar esse contador em uma secao de dados!
	mov r0, #0
	str r0, [r2]

	@Faz o registrador que aponta para a tabela de interrupções apontar para a tabela interrupt_vector
	ldr r0, =interrupt_vector
	mcr p15, 0, r0, c12, c0, 0

	ldr r0, =GPT_CR
	mov r1, #0x00000041
	str r1, [r0]

	ldr r0, =GPT_SR
	mov r1, #0x00000000
	str r1, [r0]

	ldr r0, =GPT_OCR1
	mov r1, #TIME_SZ
	str r1,[r0]

	ldr r0, =GPT_IR
	mov r1, #1
	str r1, [r0]

	@ Configura entrada/saida GPIO
	@ 0x7c003fff ou 0xfffc003e
	ldr r0, =GDIR
	ldr r1, =0xfffc003e
	str r1, [r0]

	@ zera o vetor de callbacks
	@ldr r0, =CALLBACK_VECTOR
	@mov r1, #0
	@strb r1, [r0]

	@ zera o numero de callbacks ativas
	ldr r0, =ACTIVED_CALLBACKS
	mov r1, #0
	str r1, [r0]

	ldr r0, =ACTIVED_ALARMS
	mov r1, #0
	str r1, [r0]
	@ Ajustar a pilha do modo IRQ.
	@ Você deve iniciar a pilha do modo IRQ aqui. Veja abaixo como usar a instrução MSR para chavear de modo.
	@ ...


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

	@instrucao msr - habilita interrupcoes
	msr CPSR_c, #0x13
	ldr sp, =STACK_SUPERVISOR
	msr CPSR_c, #0x12				@ IRQ
	ldr sp, =STACK_IRQ
	msr CPSR_c, #0x10       @ SOR mode, IRQ/FIQ enabled
	ldr sp, =STACK_USER
	ldr pc, =START


@ ****************************************************************************
SOFTWARE_INT_HANDLER:
	push {r1-r6, r8} @ (?) precisa dar push em r1-r3
	cmp r7, #16
	beq svc_read_sonar @ ok
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
	beq svc_supervisor
	@ valor invalido de r7
	b SOFTWARE_INT_HANDLER_ERROR

svc_read_sonar:	@ duvida quanto ao sinal ?
	@ r0 = Id sonar

	@ valor valido r0
	cmp r0, #15
	bhi svc_read_sonar_error @ coloca -1

	@ seleciona o sensor (mux) e trigger = 0
	mov r1, #0xffffffc1 @ mascara 1100 0001
	orr r0, r1, r0, lsl #2 @ ver se funciona (?)
	@ r0 -> sensor na posicão 5:2 e trigger em '0' e resto em '1'

	ldr r1, =DR         @ r1 <- endereco DR
	str r0, [r1]

	mov r2, #200
delay_1:
	sub r2,r2, #1
	cmp r2, #0
	bne delay_1


	@ trigger = 1
	ldr r0, [r1]
	orr r0, r0, #2
	str r0, [r1]

	mov r2, #200
delay_2:
	sub r2,r2, #1
	cmp r2, #0
	bne delay_2

	@ trigger = 0
	mov r2, #0xfffffffd
	ldr r0, [r1]
	and r0, r0, r2
	str r0, [r1]

	ldr r2, =DR
espera_flag:
	ldr r0, [r2]
	and r0, r0, #1      @ carrega flag em r0
	cmp r0, #1
	bne espera_flag

	ldr r0, [r2]
	mov r0, r0, lsr #6  @ ajusta a posicao de SONAR_DATA
	ldr r1, =0x00000fff
	and r0, r0, r1      @ ignora o resto, deixa apenas [11:0]
	b SOFTWARE_INT_HANDLER_END

svc_register_proximity_callback:
	@ r0 = Id
	@ r1 = Limiar
	@ r2 = function

	ldr r4, =ACTIVED_CALLBACKS
	ldr r5, [r4]
	cmp r5, #MAX_CALLBACKS
	bhs too_many_callbacks

	cmp r0, #15
	bhi svc_register_proximity_callback_id_invalid

	ldr r3, =CALLBACK_SONAR_BASE
	str r0, [r3, r5]
	ldr r3, =CALLBACK_THRESHOLD_BASE
	str r1, [r3, r5]
	ldr r3, =CALLBACK_FUNCTION_BASE
	str r2, [r3, r5]

	add r5, r5, #1
	str r5, [r4]
	mov r0, #0

	b SOFTWARE_INT_HANDLER_END

svc_set_motor_speed:
	@ r0 = Id motor
	@ r1 = velocidade
	cmp r1, #63
	bhi svc_set_motor_speed_velocity_invalid
	@ cmp r0, #0
	@ beq set_motor_r0
	@ cmp r0, #1
	@ beq set_motor_r1
	cmp r0, #1
	bhi svc_set_motor_speed_id_invalid
	@ habilita w1, copia motor1_speed e desabilita trigger
set_motor_r1:
	moveq r1, r1, lsl #26
	ldreq r2, =0x01fffffd
	@ habilita w0, copia motor0_speed e desabilita trigger
set_motor_r0:
	movne r1, r1, lsl #19
	ldrne r2, =0xfe03fffd

	orr r1, r1, r2
	ldr r0, =DR
	str r1, [r0]

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END

svc_set_motors_speed:
	@ r0 = velocidade motor 0
	@ r1 = velocidade motor 1
	cmp r0, #63
	bhi svc_set_motor_speed_id_invalid
	cmp r1, #63
	bhi svc_set_motor_speed_velocity_invalid

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

	ldr r1, =DR
	str r0, [r1]					@ escreve em DR

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END

svc_get_time:
	ldr r0, =CONTADOR
	ldr r0, [r0]
	b SOFTWARE_INT_HANDLER_END

svc_set_time:
	ldr r1, =CONTADOR
	str r0, [r1]
	b SOFTWARE_INT_HANDLER_END

svc_set_alarm:
	@ r0 = function
	@ r1 = system time

	ldr r4, =ACTIVED_ALARMS
	ldr r5, [r4]
	cmp r5, #MAX_ALARMS
	bhs svc_too_many_alarms

	ldr r6, =CONTADOR
	ldr r6, [r6]
	cmp r1, r6
	bls svc_time_invalid

	ldr r3, =ALARM_FUNCTION_BASE
	str r0, [r3, r5]
	ldr r3, =ALARM_TIME_BASE
	str r1, [r3, r5]

	add r5, r5, #1
	str r5, [r4]

	mov r0, #0
	b SOFTWARE_INT_HANDLER_END

svc_supervisor:
	msr CPSR_c, #0x10
	b SOFTWARE_INT_HANDLER_END

svc_read_sonar_error:
too_many_callbacks:
svc_set_motor_speed_id_invalid:
svc_too_many_alarms:
	mov r0, #0
	sub r0, r0, #1
	b SOFTWARE_INT_HANDLER_END

svc_register_proximity_callback_id_invalid:
svc_set_motor_speed_velocity_invalid:
svc_time_invalid:
	mov r0, #0
	sub r0, r0, #2
	b SOFTWARE_INT_HANDLER_END


SOFTWARE_INT_HANDLER_END:
	pop {r1-r6, r8}
	movs pc, lr

SOFTWARE_INT_HANDLER_ERROR:

@ ****************************************************************************
IRQ_HANDLER:

	ldr r0, =GPT_SR
	mov r1, #0x1
	str r1, [r0]

	ldr r0, =CONTADOR
	ldr r1, [r0]
	mov r2, #1
	add r1, r1, r2
	str r1, [r0]

	ldr r0, =ACTIVED_CALLBACKS
	mov r1, #0                        @ R1 = i

	@ *****************************************************************************
	@	Verifica Callbacks
	@	Remove e chama funcao
	@ *****************************************************************************
verify_callbacks:
	ldr r8, [r0]                      @ R8 <- actived callbacks
	cmp r1, r8                        @ i < callbacks_actived
	beq verify_callbacks_end

	ldr r5, =CALLBACK_SONAR_BASE

	@ *************************** @ chamada de sistema para leitura de sonar
	push {r0-r3}
	ldr r0, [r5, r1]              @ carrega o Id do sonar
	mov r7, #16                   @ escolhe a syscall read_sonar
	svc #0
	mov r7, r0                    @ retorno da funcao em R7
	pop {r0-r3}
	@ *************************** @ fim chamada de sistema para leitura de sonar

	ldr r5, =CALLBACK_THRESHOLD_BASE
	ldr r2, [r5, r1]              @ carrega o limiar
	cmp r7, r2                    @ if (distancia < limiar)
	bhs next_callback

	ldr r5, =CALLBACK_FUNCTION_BASE
	ldr r7, [r5, r1]                @ r7 <- function a ser chamada

	@ ***************************   @ apagar a callback
	@ decrementa callbacks ativas
	sub r8, r8, #1
	str r8, [r0]

	mov r2, r1                    @ R2 = j = num_callback
remove_callback:
	cmp r2, r8
	beq remove_callback_end       @ j < callbacks - 1

	ldr r4, =CALLBACK_SONAR_BASE
	add r2, r2, #1
	ldr r3, [r4, r2]              @ carrega sonar[i+1]
	sub r2, r2, #1
	str r3, [r4, r2]              @ salva em sonar[i]

	ldr r4, =CALLBACK_THRESHOLD_BASE
	add r2, r2, #1
	ldr r3, [r4, r2]              @ carrega threshold[i+1]
	sub r2, r2, #1
	str r3, [r4, r2]              @ salva em threshold[i]

	ldr r4, =CALLBACK_FUNCTION_BASE
	add r2, r2, #1
	ldr r3, [r4, r2]              @ carrega threshold[i+1]
	sub r2, r2, #1
	str r3, [r4, r2]              @ salva em threshold[i]

	add r2, r2, #1                @ j++
	b remove_callback
remove_callback_end:
	sub r1, r1, #1
	push {r0-r3}
	@ chama a funcao
	blx r7
	pop {r0-r3}
	mov r7, #23
	svc 0x0
next_callback:
	add r1, r1, #1                    @ i++
	b verify_callbacks
verify_callbacks_end:

@ *****************************************************************************
@	Verifica Callbacks
@	Remove a callback e chama a funcao
@ *****************************************************************************
	ldr r0, =ACTIVED_ALARMS
	mov r1, #0
verify_alarm:
	ldr r8, [r0]
	cmp r1, r8
	beq verify_alarm_end

	ldr r5, =ALARM_TIME_BASE
	@ *************************** @ chamada de sistema para leitura system time
	push {r0-r3}
	mov r7, #20
	svc #0
	mov r7, r0
	pop {r0-r3}
	@ *************************** @ fim da chamada de sistema para leitura system time

	ldr r2, [r5, r1]			@ carrega o tempo do alarme
	cmp r7, r2
	bhi next_alarm

	ldr r5, =ALARM_FUNCTION_BASE
	ldr r7, [r5, r1]			@ carrega a funcao a ser chamada

	sub r8, r8, #1				@ decrementa o num de alarmes
	str r8, [r0]

	mov r2, r1
remove_alarm:
	cmp r2, r8
	beq remove_alarm_end

	ldr r4, =ALARM_TIME_BASE
	add r2, r2, #1
	ldr r3, [r4, r2]
	sub r2, r2, #1
	str r3, [r4, r2]

	ldr r4, =ALARM_FUNCTION_BASE
	add r2, r2, #1
	ldr r3, [r4, r2]
	sub r2, r2, #1
	str r3, [r4, r2]

	add r2, r2, #1
	b remove_alarm
remove_alarm_end:
	sub r1, r1, #1				@ ajusta

	push {r0-r3}
	blx r7
	pop {r0-r3}
	mov r7, #23
	svc 0x0

next_alarm:
	add r1, r1, #1
	b verify_alarm
verify_alarm_end:


	sub lr, lr, #4
	movs pc, lr



.data

	CONTADOR: .skip 32

	ACTIVED_CALLBACKS:    .skip 4
	ACTIVED_ALARMS:		  .skip 4

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



	.skip 1000
STACK_USER:
	.skip 1000
STACK_SUPERVISOR:
	.skip 1000
STACK_IRQ:
