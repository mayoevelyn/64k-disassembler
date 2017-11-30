*-----------------------------------------------------------
* Title      : Disassembler opcode
* Written by : Evelyn Mahasin
* Date       : 11/16/2017
* Description: 
*-----------------------------------------------------------
*****************************************
* Example of using a jump table to decode an instruction
*
****************************************

* System equates

stack           EQU     $A000
currWord        EQU     %0101111010111111
mask1512        EQU     %1111000000000000
mask0806        EQU     %0000000111000000
mask08          EQU     %0000000100000000
mask1109        EQU     %0000111000000000
mask1108        EQU     %0000111100000000
mask0200        EQU     %0000000000000111
mask0503        EQU     %0000000000111000
mask0403        EQU     %0000000000011000
mask0706        EQU     %0000000011000000
mask0700		EQU		$FF
               
*****************
* Program starts here
* D0 = opcode parts
* D1 = opcode parts
* A1 = message
* A2 = buffer ptr
*****************
    ORG     $400
start
opcode
	LEA     buffer,A2       * load buffer address/init buffer ptr
    BSR		print_addr		* print address
	LEA     stack,SP        * Load the SP
	LEA     jmp_table,A0    * Index into the table
	CLR.L   D0              * Zero it
    MOVE.W  #currWord,D0    * We'll play with it here
    LSR.W   #7,D0
    LSR.W   #5,D0           * shift 12 bits to the right
    MULU    #6,D0           * Form offset     
    JSR     0(A0,D0)        * Jump indirect with index
        
jmp_table      
	JMP		code0000		* ADDI
	JMP		code0001		* MOVE.B
	JMP		code0010		* MOVE.L, MOVEA.L
	JMP		code0011		* MOVE.W, MOVEA.W
	JMP		code0100		* NOP, MOVEM, LEA, CLR, JSR, RTS
	JMP		code0101		* ADDQ
	JMP		code0110		* Bcc (BCC, BGT, BLE)
	JMP		code0111		* MOVEQ
	JMP		code1000		* DIVU, OR
	JMP		code1001		* SUB
	JMP		code1010		* NOT SUPPORTED
	JMP		code1011		* CMP
	JMP		code1100		* MULS, AND
	JMP		code1101		* ADD, ADDA
	JMP		code1110		* LSL, LSR, ASR, ASL, ROL, ROR
	JMP		code1111		* NOT SUPPORTED

******************
* Opcode subroutine
******************

******************
* code 0000
* ADDI
******************
code0000
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask1108,D0    * mask bits 11-8
    LSR.W   #8,D0			* shift D0 8 bits right
    
    MOVE.W  #currWord,D1    * move opcode word to D1
    ANDI.W  #mask0706,D1    * mask bits 7-6
    LSR.W   #6,D1           * shift D1 6 bits right
    
    CMPI.B	#3,D1			* check that size field is valid
    BEQ		bad_op			* if equal, bad opcode
    
    CMPI.B	#6,D0			* check rest of bits
    BNE		bad_op			* if not equal, bad opcode
    LEA		str_addi,A1
    BSR		print			* load str ADDI to buffer
    BSR		size2			* handle size
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    BRA		next_word

******************
* code 0001
* MOVE.B
******************
code0001
	LEA		str_move,A1
    BSR		print			* load str ADDI to buffer
    BSR		size_b			* load .B to buffer
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    BRA		next_word

******************
* code 0010
* MOVE.L, MOVEA.L
******************
code0010
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask0806,D0    * mask bits 8-6
    LSR.W   #6,D0           * shift D0 6 bits right
    CMPI.B	#1,D0			* if 1, is MOVEA.L
    BNE.S	op_move_l		* if not, is MOVE.L
op_movea_l
	LEA		str_movea,A1
    BSR		print			* load str ADDI to buffer
    BSR		size_l			* load .L to buffer
    LEA		space3,A1
    BSR		print			* load 3 spaces to buffer
    BRA		next_word
op_move_l
	LEA		str_move,A1
    BSR		print			* load str ADDI to buffer
    BSR		size_l			* load .L to buffer
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    BRA		next_word
    
******************
* code 0011
* MOVE.W, MOVEA.W
******************
code0011
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask0806,D0    * mask bits 8-6
    LSR.W   #6,D0           * shift D0 6 bits right
    CMPI.B	#1,D0			* if 1, is MOVEA.W
    BNE.S	op_move_w		* if not, is MOVE.W
op_movea_w
	LEA		str_movea,A1
    BSR		print			* load str ADDI to buffer
    BSR		size_W			* load .W to buffer
    LEA		space3,A1
    BSR		print			* load 3 spaces to buffer
    BRA		next_word
op_move_w
	LEA		str_move,A1
    BSR		print			* load str ADDI to buffer
    BSR		size_W			* load .W to buffer
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    BRA		next_word
    
************************************************************************
* code 0100
* NOP, MOVEM, LEA, CLR, JSR, RTS
************************************************************************
code0100
    MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask0806,D0    * mask bits 8-6
    LSR.W   #6,D0           * shift D0 6 bits right
    
    MOVE.W  #currWord,D1    * move opcode word to D1
    ANDI.W  #mask1109,D1    * mask bits 11-9 
    LSR.W   #7,D1
    LSR.W   #2,D1           * shift D1 9 bits right
    
******************
* Bits 08-06
* 000 - CLR.B
* 001 - NOP, CLR.W, RTS
* 010 - MOVEM.W, JSR, CLR.L
* 011 - MOVEM.L
* 111 - LEA
******************
    CMPI.B	#0,D0
    BEQ 	op_clr_b
    CMPI.B	#1,D0
    BEQ 	op_0100_001
    CMPI.B	#2,D0
    BEQ 	op_0100_010
    CMPI.B	#3,D0
    BEQ 	op_movem_l
    CMPI.B	#7,D0
    BEQ 	op_lea
    
******************
* Bits 08-06
* 000 - CLR.B
******************
op_clr_b
	CMPI.B	#1,D1			* check rest of bits
	BNE		bad_op			* quit if bad
	LEA		str_clr,A1
	BSR		print			* print CLR
	BSR     size_b          * print .B
	BRA		next_word

******************
* Bits 08-06
* 001 - NOP, CLR.W, RTS
******************
******************
* Bits 11-9
* 001 - CLR.W
* 111 - NOP,RTS
******************
op_0100_001
	CMPI.B  #7,D1           * nop or rts
	BEQ     nop_or_rts
	
* only CLR.W case left
op_clr_w
	CMPI.B	#1,D1			* check rest of bits
	BNE		bad_op			* quit if bad
	LEA		str_clr,A1
	BSR		print			* print CLR
	BSR     size_w          * print .W
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word
	
nop_or_rts
    MOVE.W  #currWord,D0    * load currWord to D0
    ANDI.W  #mask0200,D0    * mask bits 2-0

    MOVE.W  #currWord,D1    * load currWord to D1
    ANDI.W  #mask0503,D1    * mask bits 5-3
    LSR.W   #3,D1           * shift 3 bits right

    CMPI.B  #5,D0           * RTS
    BEQ     op_rts
* only NOP case left
op_nop
    CMPI.B  #1,D0           * check rest of bits
    BNE     bad_op          * if bad
    
    CMPI.B  #6,D1           * check rest of bits
    BNE     bad_op          * if bad

	LEA		str_nop,A1
	BSR		print			* load NOP to buffer
	LEA		space7,A1
	BSR		print			* print 7 spaces
	BRA		next_word

op_rts
    CMPI.B  #6,D1           * check rest of bits
    BNE     bad_op          * if bad
	LEA		str_rts,A1
	BSR		print			* load RTS to buffer
	LEA		space7,A1
	BSR		print			* print 7 spaces
	BRA		next_word

******************
* Bits 08-06
* 010 - MOVEM.W, JSR, CLR.L
******************
op_0100_010
	CMPI.B  #7,D1           * check rest of bits
    BEQ     op_jsr          * is JSR
    CMPI.B  #1,D1           * check rest of bits
    BEQ     op_clr_l        * is CLR.L
    * only MOVEM.W case left
op_movem_w
	* check rest of bits
	* only care about bits 11 and 9
	* bit 10 is dr, handled by EA
	ANDI.B	#5,D1			* strips bit 1 of D1
	CMPI.B  #4,D1           * check bits 11 and 9
    BNE     bad_op          * if bad
	* passed the test, let it print!
	LEA		str_movem,A1
	BSR		print			* load MOVEM to buffer
	BSR		size_w			* load .W to buffer
	LEA		space3,A1
	BSR		print			* print 3 spaces
	BRA		next_word
op_jsr
	LEA		str_jsr,A1
	BSR		print			* load JSR to buffer
	LEA		space7,A1
	BSR		print			* print 7 spaces
	BRA		next_word
op_clr_l
	LEA		str_clr,A1
	BSR		print			* load CLR to buffer
	BSR		size_l			* load .L to buffer
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word

******************
* Bits 08-06
* 011 - MOVEM.L
******************
op_movem_l
	* check rest of bits
	* only care about bits 11 and 9
	* bit 10 is dr, handled by EA
	ANDI.B	#5,D1			* strips bit 1 of D1
	CMPI.B  #4,D1           * check bits 11 and 9
    BNE     bad_op          * if bad
	* passed the test, let it print!
	LEA		str_movem,A1
	BSR		print			* load MOVEM to buffer
	BSR		size_L			* load .L to buffer
	LEA		space3,A1
	BSR		print			* print 3 spaces
	BRA		next_word

******************
* Bits 08-06
* 111 - LEA
******************
op_lea
    LEA		str_lea,A1
	BSR		print			* load LEA to buffer
	LEA		space7,A1
	BSR		print			* print 7 spaces
	BRA		next_word
************************************************************************

******************
* code 0101
* ADDQ
******************
code0101
    MOVE.W  #currWord,D0    * move opcode word to D0
    MOVE.W  D0,D1    		* move opcode word to D1

    ANDI.W  #mask08,D0		* mask bit 8
    
    CMPI.W	#0,D0			* bit 8 should be 0
    BNE		bad_op			* BAD! BAD OP! HISS
    
    LEA		str_addq,A1
	BSR		print			* load ADDQ to buffer
	
    ANDI.W  #mask0706,D1    * mask bits 7-6
    LSR.W   #6,D1           * shift D1 6 bits right
    
    CMPI.B	#3,D1			* check that size field is valid
    BEQ		bad_op			* if equal, bad opcode
    
    BSR		size2			* handle size
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    BRA		next_word

******************
* code 0110
* Bcc (BCC, BGT, BLE)
******************
code0110
	MOVE.W  #currWord,D0    * move opcode word to D0
	MOVE.W  D0,D1		    * move opcode word to D1
	
    ANDI.W  #mask1108,D0	* mask bits 11-8
    LSR.W   #8,D0			* shift D0 8 bits right
    
    ANDI.W  #mask0700,D1	* mask bit 7-0 for displacement
    
    CMPI.B	#4,D0			* BCC case
    BEQ.S	op_bcc
    CMPI.B	#$E,D0			* BGT case
    BEQ.S	op_bgt
    
* BLE case left  
op_ble
	CMPI.B	#$F,D0			* check remaining bits
	BNE		bad_op			* Bcc op not supported
	
	LEA		str_ble,A1
	BSR		print			* load BLE to buffer
	BSR		bcc_size		* deal with size
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word
op_bcc
	LEA		str_bcc,A1
	BSR		print			* load BCC to buffer
	BSR		bcc_size		* deal with size
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word
op_bgt
	LEA		str_bgt,A1
	BSR		print			* load BGT to buffer
	BSR		bcc_size		* deal with size
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word
	
* Bcc size subroutine, using D1 containing last 8 bits
bcc_size
	CMPI.B	#0,D1			* if displacement byte is 0 
	BEQ.S	bcc_w			* it is .W
bcc_s
	BSR		size_s			* if not, print .S
	RTS
bcc_w
	BSR		size_w			* print .W
	RTS

******************
* code 0111
* MOVEQ
******************
code0111
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask08,D0		* mask bit 8
	CMPI.W	#0,D0			* should all be 0
	BNE		bad_op			* bad if not
	LEA		str_moveq,A1
	BSR		print			* load MOVEQ to buffer
	LEA		space5,A1
	BSR		print			* print 5 spaces
	
	BRA		next_word

******************
* code 1000
* DIVU, OR
******************
code1000
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask0806,D0	* mask bits 8-6
    LSR.W   #6,D0			* shift D0 6 bits right
    
    CMPI.B	#3,D0			* DIVU case
    BEQ.S	op_divu
    CMPI.B	#7,D0			* bad case
    BEQ		bad_op
* OR case left
op_or
	LEA		str_or,A1
	BSR		print			* load OR to buffer
	MOVE.B	D0,D1			* prep D1 for size
	BSR		size3			* handle size printing
	LEA		space6,A1
	BSR		print			* print 6 spaces
	BRA		next_word
op_divu
	LEA		str_divu,A1
	BSR		print			* load DIVU to buffer
	LEA		space6,A1
	BSR		print			* print 6 spaces
	BRA		next_word

******************
* code 1001
* SUB
******************
code1001
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask0806,D0	* mask bits 8-6
    LSR.W   #6,D0			* shift D0 6 bits right
    
    * bad cases
    CMPI.B	#3,D0			* bad opmode case
    BEQ		bad_op
    CMPI.B	#7,D0			* bad opmode case
    BEQ		bad_op
    
    LEA		str_sub,A1
	BSR		print			* load SUB to buffer
	MOVE.B	D0,D1			* prep D1 for size
	BSR		size3			* handle size printing
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word

******************
* code 1010
* NOT SUPPORTED
******************
code1010
    BRA     bad_op			* not supported

******************
* code 1011
* CMP
******************
code1011
    MOVE.W  #currWord,D0    * move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
    
    ANDI.W  #mask08,D0		* mask bit 8
    
    * prep D1 for size
    ANDI.W  #mask0706,D1	* mask bits 7-6
    LSR.W   #6,D1			* shift D1 6 bits right
    
    * bad cases
    CMPI.W	#0,D0			* bad opmode case
    BNE		bad_op
    CMPI.B	#3,D1			* bad opmode case
    BEQ		bad_op
    
    LEA		str_cmp,A1
	BSR		print			* load CMP to buffer
	BSR		size2			* handle size printing
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word

******************
* code 1100
* MULS, AND
******************
code1100
	MOVE.W  #currWord,D0    * move opcode word to D0
    ANDI.W  #mask0806,D0	* mask bits 8-6
    LSR.W   #6,D0			* shift D0 6 bits right
    
    CMPI.B	#7,D0			* MULS case
    BEQ.S	op_muls
    CMPI.B	#3,D0			* bad case
    BEQ		bad_op
* AND case left
op_and
	LEA		str_and,A1
	BSR		print			* load AND to buffer
	MOVE.B	D0,D1			* prep D1 for size
	BSR		size3			* handle size printing
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word
op_muls
	LEA		str_muls,A1
	BSR		print			* load MULS to buffer
	LEA		space6,A1
	BSR		print			* print 6 spaces
	BRA		next_word

******************
* code 1101
* ADD, ADDA
******************
code1101
	MOVE.W  #currWord,D1    * move opcode word to D1
    ANDI.W  #mask0806,D1	* mask bits 8-6
    LSR.W   #6,D1			* shift D1 6 bits right
    
    * ADDA cases
    CMPI.B	#3,D1
    BEQ.S	op_adda
    CMPI.B	#7,D1
    BEQ.S	op_adda
    
* ADD cases left
op_add
	LEA		str_add,A1
	BSR		print			* load ADD to buffer
	BSR		size3			* handle size printing
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BRA		next_word

op_adda
	LEA		str_adda,A1
	BSR		print			* load ADDA to buffer
	BSR		size3			* handle size printing
	LEA		space4,A1
	BSR		print			* print 4 spaces
	BRA		next_word

******************
* code 1110
* LSL, LSR, ASR, ASL, ROL, ROR
******************
code1110
	MOVE.W  #currWord,D1    * move opcode word to D1
	MOVE.W	D1,D0			* move opcode word to D0
	
    ANDI.W  #mask0706,D1	* mask bits 7-6
    LSR.W   #6,D1			* shift D1 6 bits right
        
* these instructions have
* register and memory versions

* memory version cases
    CMPI.B	#3,D1			* bits 7-6 form #3
    BEQ		mem_ver			* branch to memory version
* rest are register versions
reg_ver
	ANDI.W  #mask0403,D0	* mask bits 4-3
    LSR.W   #3,D0			* shift D0 3 bits right
    
    CMPI.B	#0,D0			* ASd case
op_a
op_lsr
op_asl
op_asr
op_rol
op_ror

******************
* bits 11-8
* 0 - ASR
* 1 - ASL
* 2 - LSR
* 3 - LSR
* 4 - ROXR	* not supported
* 5 - ROXL	* not supported
* 6 - ROR
* 7 - ROL
******************
mem_ver
	LEA     bra_table,A0	* Index into the table
	ANDI.W  #mask1108,D0	* mask bits 11-8
    LSR.W   #8,D0			* shift D0 8 bits right
    MULU    #$A,D0			* Form offset     
    JSR     0(A0,D0)        * Jump indirect with index
bra_table
op_asr_m
	LEA		str_asr,A1
	BSR		print			* load ASR to buffer
	BRA		next_word
op_asl_m
	LEA		str_asl,A1
	BSR		print			* load ASL to buffer
	BRA		next_word
op_lsr_m
	LEA		str_lsr,A1
	BSR		print			* load LSR to buffer
	BRA		next_word
op_lsl_m
	LEA		str_lsl,A1
	BSR		print			* load LSL to buffer
	BRA		next_word
op_roxr_m
	NOP						* ROXR not supported
	NOP						* 7 op words filler
	NOP						* 5 NOPs + BRA bad_op
	NOP
	NOP
	BRA		bad_op			* 2 op words
op_roxl_m
	NOP						* ROXL not supported
	NOP						* 7 op words filler
	NOP						* 5 NOPs + BRA bad_op
	NOP
	NOP
	BRA		bad_op			* 2 op words
op_ror_m
	LEA		str_ror,A1
	BSR		print			* load ROR to buffer
	BRA		next_word
op_rol_m
	LEA		str_rol,A1
	BSR		print			* load ROL to buffer
	BRA		next_word

******************
* code 1111
* NOT SUPPORTED
******************
code1111
    BRA     bad_op			* not supported
        
******************
* Subroutine: chk_flag
* Checks D4.
*	0 - good
*	1 - fail at i/o
*	2 - fail at opcode
*	3 - fail at ea
******************     
chk_flag
		CMPI.B	#0,D4
		BNE.S	fail
good
		RTS
fail
		BRA		print_data

******************
* Subroutine: bad_op
* If the opcode is not supported or garbage bits
******************
bad_op
    STOP        #$2700

******************
* Subroutine: print_data TEMPORARY
******************
print_data
    STOP        #$2700
    
* temp print SR
print
print_loop
    MOVE.B  (A1)+,(A2)+     * move a byte, and progress both pointers
print_main
	CMPI.B  #00,(A1)        * check if we hit 00
	BNE     print_loop      * if not, push next byte to buffer
    RTS
    
* temp print memory address
print_addr
	MOVE.B	#0,count		* initialize counter
print_addr_loop
    MOVE.B  (A1)+,(A2)+     * move a byte, and progress both pointers
    ADD.B	#1,count		* increase counter
print_addr_main
	CMPI.B  #8,count        * check if we hit 00
	BNE     print_addr_loop * if not, push next byte to buffer
	LEA		space2,A1
	BSR.S	print			* print 2 spaces
    RTS
        
* temp next word SR
next_word
		STOP	#$2700
		
***********************************************************
* Size subroutines
* Uses D1
* Prints the size of the operation

******************
* Subroutine: size1
* Prints a dot + size
* 1 bit
*	W - 0
*	L - 1
******************
size1
	CMPI.B	#0,D1		* compare to 0
	BEQ.S	size_w		* print w
	BRA		size_l		* print l if not 0

******************
* Subroutine: size2
* Prints a dot + size
* 2 bits
*	B - 00
*	W - 01,11
*	L - 10
******************
size2
	* branch to b
	CMPI.B	#0,D1		* compare to 0
	BEQ.S	size_b
	* branch to w
	CMPI.B	#1,D1		* compare to 1
	BEQ.S	size_w
	CMPI.B	#3,D1		* compare to 3
	BEQ.S	size_w
	* else print l
	BRA		size_l
	
******************
* Subroutine: size3
* Prints a dot + size
* 3 bits
*	B - 000,100
*	W - 001,011,101
*	L - 010,110,111
******************
size3
	* branch to b
	CMPI.B	#0,D1		* compare to 0
	BEQ.S	size_b
	CMPI.B	#4,D1		* compare to 4
	BEQ.S	size_b
	* branch to w
	CMPI.B	#1,D1		* compare to 1
	BEQ.S	size_w
	CMPI.B	#3,D1		* compare to 3
	BEQ.S	size_w
	CMPI.B	#5,D1		* compare to 5
	BEQ.S	size_w
	* the rest is l
	BRA		size_l
		
******************
* Size printing subroutines
* Prints b/w/l/s
******************
size_b
	LEA		str_b,A1	* size is b
	JSR		print
	RTS
size_w
	LEA		str_w,A1	* size is w
	JSR		print
	RTS
size_l
	LEA		str_l,A1	* size is l
	JSR		print
	RTS
size_s
	LEA		str_s,A1	* size is l
	JSR		print
	RTS
***********************************************************

* Opcode strings
str_nop		DC.B	'NOP',0
str_move	DC.B    'MOVE',0
str_movea	DC.B	'MOVEA',0
str_moveq	DC.B	'MOVEQ',0
str_movem	DC.B	'MOVEM',0
str_add	    DC.B	'ADD',0
str_adda	DC.B	'ADDA',0
str_addi    DC.B	'ADDI',0
str_addq	DC.B	'ADDQ',0
str_sub   	DC.B	'SUB',0
str_muls  	DC.B	'MULS',0
str_divu 	DC.B	'DIVU',0
str_lea  	DC.B	'LEA',0
str_clr		DC.B	'CLR',0
str_and	    DC.B	'AND',0
str_or   	DC.B	'OR',0
str_lsl	    DC.B	'LSL',0
str_lsr  	DC.B	'LSR',0
str_asr  	DC.B	'ASR',0
str_asl	    DC.B	'ASL',0
str_rol	    DC.B	'ROL',0
str_ror  	DC.B	'ROR',0
str_cmp	    DC.B	'CMP',0
str_bcc  	DC.B	'BCC',0
str_bgt  	DC.B	'BGT',0
str_ble	    DC.B	'BLE',0
str_jsr	    DC.B	'JSR',0
str_rts  	DC.B	'RTS',0

* Size strings
str_b		DC.B    '.B',0
str_w       DC.B    '.W',0
str_l       DC.B    '.L',0
str_s       DC.B    '.S',0

* Misc strings
space1		DC.B	' ',0
space2		DC.B	'  ',0
space3		DC.B	'   ',0
space4		DC.B	'    ',0
space5		DC.B	'     ',0
space6		DC.B	'      ',0
space7		DC.B	'       ',0

* Buffer (temp)
buffer      DS.B    20      * 10b for memory, 10b for opcode
count		DS.B	1		* counter
currAddr	DS.L	1		* address of current word

        	END     $400 





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
