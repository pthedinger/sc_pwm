/*
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2010
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/

//
// This implements all PWM configurations for 3 channel
// PWM. The mode of operation should be updated using
// the appropriate functions in the dsc_pwm_cli API
//
// 26 Apr 2010

#include <xs1.h>

#ifdef __pwm_config_h_exists__
#include "pwm_config.h"
#endif

#include "pwm_common.h"

.extern pwm_op_simple

.section .text



// Main PWM Service routine

.globl pwm_op_simple.nstackwords
.globl pwm_op_simple.maxthreads
.globl pwm_op_simple.maxtimers
.globl pwm_op_simple.maxchanends

.linkset pwm_op_simple.nstackwords, 7
.linkset pwm_op_simple.maxchanends, 1
.linkset pwm_op_simple.maxtimers, 0
.linkset pwm_op_simple.maxthreads, 0

.cc_top pwm_op_simple.func, pwm_op_simple
.globl pwm_op_simple

// r0 - buffer index
// r1 - p_pwm[],
// r2 - channel
// r3 - pointer to control structure
pwm_op_simple:
	entsp 7

	// callee save
	stw r4, sp[1]
	stw r5, sp[2]
	stw r6, sp[3]
	stw r7, sp[4]
	stw r8, sp[5]

	/*
	 * now arrange stuff:
	 * r0 - pwm port 0, r1 - 			 r2 - out_data0,
	 * r3 - ctrl ptr	r4 - mode,  	 r5 - sync_point
	 * r6 - tmp0        r7 - tmp1,  	 r8 - chanend
	 * r9 - 			r10-
	 */

	// load up ports array
	stw r1, sp[6]
	mov r7, r1 // move p_pwm[] to r7
	mov r6, r0 // move buffer id to r6
	mov r8, r2 // move channel to r8

	//prep for reading ports
	ldc r0, 12 // entry is 4x3 bytes long
	mul r0, r6, r0 // buf * length, to get to the right place in the array
	add r1, r0, r3 // r1 = pointer to port id

	// r0 = chan_id_buf[buf]
	ldw r0, r1[0]
	ldw r0, r7[r0] // get channel

	// prep for reading data_out
	ldc r4, OFFSET_OF_DATA_OUT
	add r4, r3, r4
	ldc r7, (SIZE_OF_T_DATA_OUT*3) // size of structure
	mul r7, r7, r6 // buf * struct size -> to get to the right place in the array
	add r2, r7, r4 // add offset to pointer, now at top of correct array of structs

	// read mode
	ldc r7, OFFSET_OF_MODE_BUF
	add r4, r3, r7
	ldaw r4, r4[r6]
	ldw r4, r4[0]
	
	// get current time stamp
	getts r5, res[r0]

	// calculate first time point
	ldc r6, INIT_SYNC_INCREMENT
	add r5, r5, r6
	mkmsk r6, 16
	and r5, r6, r5

	// check mode and branch as appropriate
JUMP_TO_MODE:
	eq r6, r4, 1
	bt r6, PWM_MODE_1
	eq r6, r4, 2
	bt r6, PWM_MODE_2

PWM_STOP:
	bu	PWM_STOP

PWM_MODE_1:
	// Channel 0
	ldw r6, r2[0]
	sub r6, r5, r6
	setpt res[r0], r6
	ldw r6, r2[1]
	out res[r0], r6

	// setup event
	ldap r11, GO_UPDATE_M1
	setv res[r8], r11
	eeu res[r8]
	setsr 0x1
	// clear events
	clrsr 0x1
	clre

	// update SYNC timestamp
	ldc r6, SYNC_INCREMENT
	add r5, r6, r5
	mkmsk r6, 16
	and r5, r6, r5

	bu PWM_MODE_1
	
GO_UPDATE_M1:
	// get buffer number
	chkct res[r8], 0x1
	outct res[r8], 0x1
	in r6, res[r8]
	chkct res[r8], 0x1
	outct res[r8], 0x1

	// load up ports
	ldw r7, sp[6]

    //prep for reading ports
    ldc r0, 12 // entry is 4x3 bytes long
    mul r0, r6, r0 // buf * length, to get to the right place in the array
    add r1, r0, r3 // r1 = pointer to port id

    // r0 = chan_id_buf[buf]
    ldw r0, r1[0]
    ldw r0, r7[r0] // get channel

    // prep for reading data_out
    ldc r4, OFFSET_OF_DATA_OUT
    add r4, r3, r4
    ldc r7, (SIZE_OF_T_DATA_OUT*3) // size of structure
    mul r7, r7, r6 // buf * struct size -> to get to the right place in the array
    add r2, r7, r4 // add offset to pointer, now at top of correct array of structs

    // read mode
    ldc r7, OFFSET_OF_MODE_BUF
    add r4, r3, r7
    ldaw r4, r4[r6]
    ldw r4, r4[0]

	// update SYNC timestamp
	ldc r6, SYNC_INCREMENT
	add r5, r6, r5
	mkmsk r6, 16
	and r5, r6, r5

	bu JUMP_TO_MODE

PWM_MODE_2:
	// Channel 0
	ldw r6, r2[0]
	sub r6, r5, r6
	setpt res[r0], r6
	ldw r6, r2[1]
	out res[r0], r6

	// Channel 0
	ldw r6, r2[2]
	add r6, r5, r6
	setpt res[r0], r6
	ldw r6, r2[3]
	out res[r0], r6
	
	// setup event
	ldap r11, GO_UPDATE_M1
	setv res[r8], r11
	eeu res[r8]
	setsr 0x1

	// update SYNC timestamp
	ldc r6, SYNC_INCREMENT
	add r5, r6, r5
	mkmsk r6, 16
	and r5, r6, r5

	// clear events
	clrsr 0x1
	clre
	
	bu PWM_MODE_2

.cc_bottom pwm_op_simple.func
	
