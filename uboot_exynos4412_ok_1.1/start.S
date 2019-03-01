
#include "cpu.h"
#include "tiny4412_val.h"

#define CONFIG_SYS_INIT_SP_ADDR	(0x50000000*1)


.global _start
_start:
	/* use iROM stack in bl2 */
	ldr	sp, =0x02060000
	push	{lr}

	/* check reset status */
	ldr	r0, =(INF_REG_BASE + INF_REG1_OFFSET)
	ldr	r1, [r0]

	/* set CP reset to low */
	ldr	r0, =0x11000C60
	ldr	r1, [r0]
	ldr	r2, =0xFFFFFF0F
	and	r1, r1, r2
	orr	r1, r1, #0x10
	str	r1, [r0]
	ldr	r0, =0x11000C68
	ldr	r1, [r0]
	ldr	r2, =0xFFFFFFF3
	and	r1, r1, r2
	orr	r1, r1, #0x4
	str	r1, [r0]
	ldr	r0, =0x11000C64
	ldr	r1, [r0]
	ldr	r2, =0xFFFFFFFD
	and	r1, r1, r2
	str	r1, [r0]

	/* led (GPM4_0~3) on */
	ldr	r0, =0x110002E0
	ldr	r1, =0x00001111
	str	r1, [r0]
	ldr	r1, =0x0e
	str	r1, [r0, #0x04]



	bl system_clock_init          


	bl  mem_ctrl_asm_init

	bl uart_asm_init

    mov	r0, #'K'
	bl	uart_asm_putc


	bl	tzpc_init

    ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS2_OFFSET
	ldr	r1, [r0, r2]
	orr	r1, r1, #0xf
	str	r1, [r0, r2]

	bl	movi_uboot_copy

clean_bss:
	ldr r0, =__bss_start
	ldr r1, =__bss_end
	mov r3, #0
	cmp r0, r1
	ldreq pc, =on_ddr
clean_loop:
	str r3, [r0], #4
	cmp r0, r1	
	bne clean_loop		
	ldr pc, =on_ddr

on_ddr:
	ldr sp, =0x50000000
	ldr pc, =main

	
	
/*
 * uart_asm_init: Initialize UART in asm mode, 115200bps fixed.
 * void uart_asm_init(void)
 */
	.globl uart_asm_init
uart_asm_init:

	/* set GPIO to enable UART */
	@ GPIO setting for UART for UART0/1/2/3
	ldr	r0, =0x11400000
	ldr	r1, =0x22222222
	str	r1, [r0]
	ldr	r0, =0x11400020
	ldr	r1, =0x222222
	str	r1, [r0]

	ldr	r0, =S5PV310_CLOCK_BASE
	ldr	r1, =CLK_SRC_PERIL0_VAL
	ldr	r2, =CLK_SRC_PERIL0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_DIV_PERIL0_VAL
	ldr	r2, =CLK_DIV_PERIL0_OFFSET
	str	r1, [r0, r2]

	ldr	r0, =S5PV310_UART_CONSOLE_BASE
	ldr	r1, =0x111
	str	r1, [r0, #0x08]

	mov	r1, #0x3
	str	r1, [r0, #0x00]

	ldr	r1, =0x3c5
	str	r1, [r0, #0x04]

	ldr	r1, =UART_UBRDIV_VAL
	str	r1, [r0, #0x28]

	ldr	r1, =UART_UDIVSLOT_VAL
	str	r1, [r0, #0x2C]

	ldr	r1, =0x4f4f4f4f
	str	r1, [r0, #0x20]		@'O'

	mov	pc, lr

 	.globl uart_asm_putc
uart_asm_putc:
	push	{r9}

	ldr	r9, =S5PV310_UART_CONSOLE_BASE
	str	r0, [r9, #0x20]
	ldr	r9, =0x20000				@delay

.Luartputc:
	sub	r9, r9, #1
	cmp	r9, #0
	bne	.Luartputc

	pop	{r9}
	mov	pc, lr

	.globl uart_asm_putx
uart_asm_putx:
	stmfd sp!, {r3, r4, r5, lr}

	mov	r5, r0
	mov	r4, #28
.Luartputx:
	mov	r0, r5, asr r4
	and	r0, r0, #15
	cmp	r0, #9
	addle	r0, r0, #48
	addgt	r0, r0, #55
	bl	uart_asm_putc
	sub	r4, r4, #4
	cmn	r4, #4
	bne	.Luartputx

	ldmfd sp!, {r3, r4, r5, pc}
	


	
	

tzpc_init:

	ldr	r0, =ELFIN_TZPC0_BASE
	mov	r1, #0x0
	str	r1, [r0]
	mov	r1, #0xff
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	mov	r1, #0xbd
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	mov	r1, #0xff
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC1_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC2_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC3_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC4_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC5_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	mov	pc, lr


