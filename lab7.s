.globl _start

.data

input_buffer: .skip 32 @ 32 bytes
output_buffer: .skip 72 @ 72 bytes
barra_n: .skip 1
space: .skip 1

vetor_atual: .skip 24544
vetor_anterior: .skip 24544

.text
.align 4
@ main
_start:
  mov r0, #10
  str r0, =barra_n
  mov r0, #32
  str r0, =space

  ldr r0, =input_buffer
  mov r1, #4
  bl read

  mov r4, r0        @ r4 = retorno funcao
  ldr r0, =input_buffer
  mov r1, r4
  bl hexToDec

  mov r4, r0        @ r4 = valor n em decimal s/ sinal
  mov r1, #0        @ j
  mov r0, #0        @ i

  ldr r5, =vetor_anterior
  ldr r6, =vetor_atual

pascal_init:
  cmp r0, r4
  beq pascal_end    @ while (i < N)

calcula_init:
  cmp r1, r0
  bhi calcula_end   @ while (j <= i)

  mov r2, #0        @ acumulador

  cmp r0, #0        @ if (i == 0)
  moveq r2, #1      @ sem sinal

  cmp r1, #0
  bne if_j_end      @ if (j != 0)
  sub r7, r1, #1
  ldr r3, [r5, r7, lsl, #2]    @ r3 = vetor_anterior[j-1]
  add r2, r2, r3      @ r2 = r2 + vetor_anterior[j-1]
if_j_end:

  cmp r1, r0
  bne if_i_j_end
  ldr r3, [r5, r1, lsl, #2]    @ r3 = vetor_anterior[j]
  add r2, r2, r3
if_i_j_end:

  str r2, [r6, r1, lsl, #2]    @ vetor_atual[j] = valor
  @ precisa converter r2 para hex e para char
  str r2, =output_buffer

  mov r7, r0
  mov r8, r1
  mov r0, =output_buffer
  mov r1, #9
  bl write
  mov r0, r7
  mov r1, r8

  add r1, r1, #1      @ j++
  b calcula_init
calcula_end:
  @putchar('\n');
  mov r7, r0
  mov r8, r1
  mov r0, =barra_n
  mov r1, #1
  bl write
  mov r0, r7
  mov r1, r8

  mov r7, r5
  mov r5, r6
  mov r6, r5
  b pascal_init

pascal_end
  mov r0, #0
  bl exit


read:
  push {r4, r5, lr}
  mov r4, r0
  mov r5, r1
  mov r0, #0         @ stdin file descriptor = 0
  mov r1, r4         @ endereco do buffer
  mov r2, r5         @ tamanho maximo.
  mov r7, #3         @ read
  svc 0x0
  pop {r4, r5, lr}
  mov pc, lr

write:
  push {r4,r5, lr}
  mov r4, r0
  mov r5, r1
  mov r0, #1         @ stdout file descriptor = 1
  mov r1, r4         @ endereco do buffer
  mov r2, r5         @ tamanho do buffer.
  mov r7, #4         @ write
  svc 0x0
  pop {r4, r5, lr}
  mov pc, lr

@ converte entrada hex para dec
@ retorno em r0
hexToDec:
  push {r4, r5, lr}

  mov r4, r0        @ r4 = end de caracteres
  mov r5, r1        @ r5 = num de caracteres

  mov r0, #0        @ zera acumulador
  mov r1, #0        @ zera contador
hexToDec_loop:
  cmp r1, r5
  beq hexToDec_end

  ldrb r2, [r4, r1] @ r2 = string[r1]

  cmp  r2, #60      @ compara com valor entre '9' e 'A' em ASCII
  movlo r3, #48     @ 0-9
  movhi r3, #55     @ A-F

  sub  r2, r2, r3   @ converte char para valor int
  @r1 - variavel de controle
  mov r3, r1        @ contador
potencia:
  cmp  r3, #0       @
  beq potencia_end
  mov r2, r2, lsl #4 @ multiplica por 16
  sub r3, r3, #1
  b potencia

potencia_end:

  add r0, r0, r2    @ soma acumulador
  add r1, r1, #1    @ incrementa var controle
  b hexToDec_loop

hexToDec_end:
  mov r0, r2
  pop {r4, r5, lr}
  mov  pc, lr

@ decimal para hex e char
hexToChar:
  push {r2-r7, lr}
  @r0 - endereco
  @r1 - valor int

  mov r3, #0x0000000F
  mov r5, #0
hexToChar_loop:
  cmp r5, #8
  beq hexToChar_loop_end

  mov r6, r5, lsr #2
  and r4, r1, r3
  mov r4, r4, lsr r6

  cmp r4, #10
  movlo r6, #48
  movhs r6, #55

  add r4, r4, r6

  strb r4, [r0, r5]       @ string[r5] = r4

  add r5, r5, #1
  mov r3, r3, lsl #4

  b hexToChar_loop
hexToChar_loop_end:
  mov r2, #32
  strb r2, [r0, #9]


  pop {r2-r7, lr}
  mov pc, lr

exit:
  mov r7, #1        @ syscall number for exit
  svc 0x0
