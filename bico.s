.global set_motor_speed
.global set_motors_speed
.global read_sonar
.global read_sonars
.global register_proximity_callback
.global add_alarm
.global get_time
.global set_time

set_motor_speed:
	@ r0 - enderco de uma Struct
	push {r7, lr}
	ldrb r1, [r0, #1]
	ldrb r0, [r0]
	mov r7, #18
	svc #0
	pop {r7, lr}
	mov pc, lr


set_motors_speed:
	@ r0 - enderco de uma Struct
	@ r1 - enderco de uma Struct
	push {r7, lr}
	ldrb r0, [r0, #1]
	ldrb r1, [r1, #1]
	mov r7, #19
	svc #0
	pop {r7, lr}
	mov pc, lr


read_sonar:
	@ r0 - Id
	push {r7, lr}
	mov r7, #16
	svc #0
	pop {r7, lr}
	mov pc, lr


read_sonars:
	@ r0 - inicio
	@ r1 - fim
	@ r2 - distance

register_proximity_callback:
	@ r0 - sensor Id
	@ r1 - distances
	@ r2 - pointer

add_alarm:
	@ r0 - pointer
	@ r1 - Timer

get_time:
	@ r0 - where to recieve

set_time:
	@ r0 - Time
