/*
 *
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
#ifndef __PWM_COMMON_H_
#define __PWM_COMMON_H_

#ifdef __pwm_config_h_exists__
#include "pwm_config.h"
#endif

// The offset and size of components in the PWM control structure
#define OFFSET_OF_CHAN_ID  0
#define OFFSET_OF_MODE_BUF 24
#define OFFSET_OF_DATA_OUT 32
#define SIZE_OF_T_DATA_OUT 40

// Define this to limit the symmetrical PWM duty cycle to a smaller range, enabling faster update
//MB~ #define PWM_CLIPPED_RANGE

// The number of PWM channels that are supported by the symmetrical PWM
#ifndef PWM_CHAN_COUNT
#define PWM_CHAN_COUNT 3
#endif

// The number of clocks to increment between each phase
#ifndef SYNC_INCREMENT
#define SYNC_INCREMENT (PWM_MAX_VALUE)
#endif

// The initial number of clocks to wait before starting the PWM loops
#ifndef INIT_SYNC_INCREMENT
#define INIT_SYNC_INCREMENT (SYNC_INCREMENT)
#endif

// Enumerate PWM Modes
// NB These used in assembler, therefore have to be defines NOT enums!-(
#define D_PWM_MODE_0 0 // 3xSINGLE
#define D_PWM_MODE_1 1 // DOUBLE + 2xSINGLE
#define D_PWM_MODE_2 2 // 2xDOUBLE + SINGLE
#define D_PWM_MODE_3 3 // 3xDOUBLE
#define D_PWM_MODE_4 4 // LONG_SINGLE + 2xSINGLE
#define D_PWM_MODE_5 5 // LONG_SINGLE + DOUBLE + SINGLE
#define D_PWM_MODE_6 6 // LONG_SINGLE + 2xDOUBLE
#define D_PWM_MODE_7 7 // 2xLONG_SINGLE + SINGLE (WARNING Unsupported)
#define D_PWM_MODE_8 8 // 2xLONG_SINGLE + DOUBLE (WARNING Unsupported)
#define D_PWM_MODE_9 9 // 3xLONG_SINGLE (WARNING Unsupported)

#define NUM_PWM_PHASES 3 // 3-phase PWM
#define NUM_PWM_BUFS 2  // Double-buffered
#define NUM_PULSE_EDGES 2  // Max. number of edges in a pulse!

#ifndef __ASSEMBLER__

typedef enum PWM_OUTPUT_CAT
{
	LONG_SINGLE,
	SINGLE,
	DOUBLE
} e_pwm_cat;


// PWM Output data structure as laid out in pwm_op_inv assembler
/* if changing this then change the corresponding value in dsc_pwm_common.h */
typedef struct ASM_OUTDATA_TAG
{
	/* N */
	unsigned hi_ts0;  // 0
	unsigned hi_out0; // 1
	unsigned hi_ts1;  // 2
	unsigned hi_out1; // 3

	/* N' */
	unsigned lo_ts0;  // 4
	unsigned lo_out0; // 5
	unsigned lo_ts1;  // 6
	unsigned lo_out1; // 7

	/* other info */
	e_pwm_cat cat;
	unsigned value;
} ASM_OUTDATA_TYP;

// PWM control data structure as laid out in pwm_op_inv assembler for shared memory access
typedef struct ASM_CONTROL_TAG
{
	unsigned chan_id_buf[NUM_PWM_BUFS][NUM_PWM_PHASES];
	unsigned mode_buf[NUM_PWM_BUFS];
	ASM_OUTDATA_TYP pwm_out_data_buf[NUM_PWM_BUFS][NUM_PWM_PHASES];
	unsigned pwm_cur_buf;
} ASM_CONTROL_TYP;

// Structure containing data for at least one pulse edge
typedef struct PWM_EDGE_TAG
{
	unsigned time;
	unsigned pattern;
} PWM_EDGE_TYP;

// Structure containing all pulse-data for one leg of balanced line 
typedef struct PWM_PULSE_TAG
{
	PWM_EDGE_TYP edges[NUM_PULSE_EDGES]; // array of data structures for pulse edges
} PWM_PULSE_TYP;

// Structure containing all pulse-data
typedef struct PWM_OUTDATA_TAG
{
	PWM_PULSE_TYP hi; // Pulse data for high leg (V+) of balanced line
	PWM_PULSE_TYP lo; // Pulse data for low leg (V-) of balanced line

	e_pwm_cat typ;  // pulse-type  MB~
	unsigned width; // PWM Pulse width
} PWM_OUTDATA_TYP;

// Structure containing pwm output data for one phase
typedef struct PWM_PHASE_TAG // Structure containing string
{
	PWM_OUTDATA_TYP out_data;
	unsigned ord_id; // index for ordering phases in time
} PWM_PHASE_TYP;

// Structure containing pwm output data for one buffer
typedef struct PWM_BUFFER_TAG
{
	PWM_PHASE_TYP phase_data[NUM_PWM_PHASES]; // Array of phase-data structures, one for each phase
	unsigned cur_mode; // current PWM mode for this buffer
} PWM_BUFFER_TYP;

// Structure containing pwm output data for all buffers
typedef struct PWM_CONTROL_TAG
{
	PWM_BUFFER_TYP buf_data[NUM_PWM_BUFS]; // Array of buffer-data structures, one for each buffer
	unsigned tmp[8]; // Debug
	unsigned cur_buf; // current double-buffer id
} PWM_CONTROL_TYP;

#endif // #ifndef __ASSEMBLER__

#endif /*DSC_ALT_PWM_H_*/
