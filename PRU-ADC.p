// *****************************************************************************/
// file:   PRU-ADC.p
//
// brief:  Use PRU0 to TSC_ADC controller for use in general purpose A2D conversion and store data on PRU-ARM shared Memory.
//
// *****************************************************************************/
//  (C) Copyright 2016 Engenharia Eletrônica UFPel
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; version 2 of the License.             
//                                                                     
// *****************************************************************************/
//  author     J. C. Scheunemann
//
//  version    0.1     Created
// *****************************************************************************/



// Lib definitions
// Refer to this mapping in the file - pruss_intc_mapping.h
#define PRU0_PRU1_INTERRUPT     17
#define PRU1_PRU0_INTERRUPT     18
#define PRU0_ARM_INTERRUPT      19
#define PRU1_ARM_INTERRUPT      20
#define ARM_PRU0_INTERRUPT      21
#define ARM_PRU1_INTERRUPT      22

#define CONST_PRUCFG         C4
#define CONST_PRU01DRAM      C24
#define CONST_PRU10DRAM      C25
#define CONST_PRUSHAREDRAM   C28
#define CONST_DDR            C31

#define ADC_TSC    0x44E0D000	//ADC-TouchScreenControl subsystem start address
#define FIFO0COUNT (ADC_TSC + 0x00E4)
#define FIFO0DATA  (ADC_TSC + 0x0100)

#define PRUSHAREDRAM 0x00010000 //PRU-ARM shared RAM address
#define PRUDRAM1 0x00000000		//self PRU start address
#define PRUDRAM2 0x00002000		//other PRU start address
#define PRUDRAMSIZE 8192		//8kB
#define PRUSHAREDRAMSIZE 12288	//12kB

// programmer definitions 

#define tmp0  r1
#define tmp1  r2
#define miss  r3
#define mem_counter  r4
#define mem_block  r5
#define adc_  r6
#define tmp_adc r7
#define fifo0count r8
#define delay  r9
#define mem_adr r10

#define MEMBLOCK 1024
#define MEMSECTION (PRUSHAREDRAMSIZE/MEMBLOCK)
//#define out_buff  r8
//#define locals r9

  

//Start code
.origin 0
.entrypoint START

START:		//set initial value to vars and configure ADC hardware to work
	//clear vars
	LDI 	tmp0, 0x00000000
	LDI 	tmp1, 0x00000000
	LDI 	tmp2, 0x00000000
	LDI 	mem_counter, 0x00000000
	LDI 	tmp_adc, 0x00000000
	// Enable OCP master port
    LBCO      r0, CONST_PRUCFG, 4, 4
    CLR     r0, r0, 4         // Clear SYSCFG[STANDBY_INIT] to enable OCP master port
    SBCO      r0, CONST_PRUCFG, 4, 4
	//ADC init
	LDI 	adc_,	ADC_TSC			//store ADC_TSC memory address value in adc_ 
	LDI 	tmp0, 	2				//store 0010 on tmp0
	SBBO 	tmp0, adc_,	0x0010,	1	//store 0010 on (adc_+0x0010) memory position, set SYSCONFIG reg to "no idle mode"
	LDI 	tmp0,	1				//store 1on tmp0
	SBBO	tmp0, adc_, 0x004C, 1	//store 0010 on (adc_+0x004C) memory position, set ADC_CLKDIV reg by 1
	LDI 	tmp0,	0x01FE			//store on tmp0 '111111110'
	SBBO 	tmp0, adc_, 0x0054, 2	//store 111111110 on (adc_+0x0054) memory position, enable step1~step8
	//ADC channel config
    //       f   chan                m
    //       i   nel                 o
    //       f   sele                d
    //       o   c                   e
    // ------|-++/  \----+++---------/\
    // 00000000110000000001100000000001____ch0____00C01801
	LDI 	tmp0, 0x00C01801		
	SBBO	tmp0, adc_,	0x0064, 4	//configure step1 to VREFM,VREFP, fifo0, channel0 and continuous mode
    // 00000000110001000001100000000001____ch1____00C41801
	LDI 	tmp0, 0x00C41801
	SBBO	tmp0, adc_,	0x006C, 4	//configure step2 to VREFM,VREFP, fifo0, channel1 and continuous mode
    // 00000000110010000001100000000001____ch2____00C81801
	LDI 	tmp0, 0x00C81801
	SBBO	tmp0, adc_,	0x0074, 4	//configure step3 to VREFM,VREFP, fifo0, channel2 and continuous mode
    // 00000000110011000001100000000001____ch3____00CC1801
	LDI 	tmp0, 0x00CC1801
	SBBO	tmp0, adc_,	0x007C, 4	//configure step4 to VREFM,VREFP, fifo0, channel3 and continuous mode
    // 00000000110100000001100000000001____ch4____00D01801
	LDI 	tmp0, 0x00D01801
	SBBO	tmp0, adc_,	0x0084, 4	//configure step5 to VREFM,VREFP, fifo0, channel4 and continuous mode
    // 00000000110101000001100000000001____ch5____00D41801
	LDI 	tmp0, 0x00D41801
	SBBO	tmp0, adc_,	0x008C, 4	//configure step6 to VREFM,VREFP, fifo0, channel5 and continuous mode
    // 00000000110110000001100000000001____ch6____00D81801
	LDI 	tmp0, 0x00D81801
	SBBO	tmp0, adc_,	0x0094, 4	//configure step7 to VREFM,VREFP, fifo0, channel6 and continuous mode
    // 00000000110111000001100000000001____ch7____00DC1801
	LDI 	tmp0, 0x00DC1801
	SBBO	tmp0, adc_,	0x009C, 4	//configure step8 to VREFM,VREFP, fifo0, channel7 and continuous mode
	
	
	//start ADC_TSC
	LDI 	tmp0, 0x0003			//store 00000011 on tmp0
	SBBO	tmp0, adc_, 0x0040, 1	//set STEP_ID_tag to 1 and start ADC_TSC
	
	//delay for the first ADC read
	MOV delay, 1250					
DELAY1:	
	SUB delay, delay, 1                       // subtract 1 from R1
    QBNE DELAY1, delay, 0						

RUN:// "free-running" mode
	LDI tmp0, FIFO0COUNT				//Load on tmp0 FIFO0COUNT mem address		
	LBBO fifo0count ,tmp0,	0 , 1		//load on fifo0count number of samples stored on fifo0 mem
	
DELAY_CALC: //calc n cycles to delay
	MOV delay, 1250						//load int cycles delay	
	QBLT FIFO_ERROR, fifo0count, 25		//if fifo0count is Greater Than 25 samples reduce delay cycles 
	LDI delay, 450

FIFO_ERROR:
	
	QBNE ADC_FIFO_COLECTOR,fifo0count, 0 //if n samples equal 0 inc error counter, else jump to ADC_FIFO_COLECTOR
	ADD miss, miss, 1					//inc error counter
	QBNE ADC_ERROR, miss, 3				//if error counter equal 3, jump to ADC_ERROR, else jump to DELAY_RUN
	
DELAY_RUN: //execute delay
	SUB delay, delay, 1                 // subtract 1 from R1
    QBNE DELAY_RUN, delay, 0			// if delay counter not equal 0 jump DELAY_RUN, else jump RUN
	JMP RUN
	
ADC_FIFO_COLECTOR:	//Load ADC_TSC FIFO0DATA to shared ARM-PRU RAM
	LDI tmp0, FIFO0DATA					//Load on tmp0 FIFO0DATA mem address 
	LBBO tmp_adc, tmp0, 0 , 4			//load on tmp_adc ADC sample data
	LSL tmp1, tmp_adc.b2, 12			//shift to left 12 times (00000000 00000000 idCH0000 00000000)
	OR tmp1, tmp1, tmp_adc.w0			//concatenate channel ID together with sample data(idCHxxxx xxxxxxxx)
	LDI tmp0, PRUSHAREDRAM				//Load on tmp0 PRUSHAREDRAM mem address
	SBBO tmp1.w0, tmp0,mem_adr, 2		//store ADC sample data on ARM-PRU shared RAM
	ADD mem_counter,mem_counter, 2		// inc 2 mem counter
	ADD mem_adr, mem_adr, 				// inc 2 mem address
	SUB fifo0count, fifo0count, 1		// dec 1 fifo0count 
	QBEQ MEMBLOCK_CHANGE, mem_counter, MEMBLOCK //if mem_counter equal MEMBLOCK jump to MEMBLOCK_CHANGE, else jump to VERIFY_FIFO counter
	JMP VERIFY_FIFO		
	
	MEMBLOCK_CHANGE: //Change mem address controller and call ARM interrupt
		LDI mem_counter 0				//reset mem_counter
		ADD mem_block, mem_block, 1		//inc mem_block counter
		MOV r31.b0, PRU0_ARM_INTERRUPT+16//call ARM interrupt 
		QBNE VERIFY_FIFO, mem_block, MEMSECTION	//if it is not greater than the shared RAM jump to VERIFY_FIFO
		LDI mem_block, 0 				//reset mem_block counter
		LDI mem_adr, 0					//reset mem_adr
	
	VERIFY_FIFO:
	QBNE DELAY_RUN, fifo0count, 0
	JMP ADC_FIFO_COLECTOR
	
 	
ADC_ERROR:
	
	JMP DELAY_RUN


