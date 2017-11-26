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
nopex           EQU     %0100111001110001
mask1512        EQU     %1111000000000000
mask0806        EQU     %0000000111000000
mask1109        EQU     %0000111000000000

* temp spaces (copied)
space7
		LEA		space,A1
        BSR.S	print
space6
		LEA     space,A1
        BSR.S	print
space5
		LEA     space,A1
        BSR.S	print
space4
		LEA     space,A1
        BSR.S	print
space3
		LEA     space,A1
        BSR.S	print
space2
		LEA     space,A1
        BSR.S	print
space1
		LEA     space,A1
        BSR.S	print
        RTS
               
* temp print SR
print
		MOVE.B  #14,D0
        TRAP    #15
        RTS
        
* temp next word SR
next_word
		STOP	#$2700

*****************
* Program starts here
* D0 = used for bits 15-12, or 8-6
* D1 = used for bits 11-9
*****************
        ORG     $400
start
        LEA     stack,SP        * Load the SP
        LEA     jmp_table,A0    * Index into the table
        CLR.L   D0              * Zero it
        MOVE.W  #nopex,D0       * We'll play with it here
        LSR.W   #12,D0          * shift 12 bits to the right
        MULU    #6,D0           * Form offset     
        JSR     0(A0,D0)        * Jump indirect with index
        
jmp_table      
        JMP         code0000     * ADDI
        JMP         code0001     * MOVE.B
        JMP         code0010     * MOVE.L, MOVEA.L
        JMP         code0011     * MOVE.W, MOVEA.W
        JMP         code0100     * NOP, MOVEM, LEA, CLR, JSR, RTS
        JMP         code0101     * ADDQ
        JMP         code0110     * Bcc (BCC, BGT, BLE)
        JMP         code0111     * MOVEQ
        JMP         code1000     * DIVU, OR
        JMP         code1001     * SUB
        JMP         code1010     * NOT SUPPORTED
        JMP         code1011     * CMP
        JMP         code1100     * MULS, AND
        JMP         code1101     * ADD, ADDA
        JMP         code1110     * LSL, LSR, ASR, ASL, ROL, ROR
        JMP         code1111     * NOT SUPPORTED

******************
* Opcode subroutine
******************

******************
* code 0000
* ADDI
******************
code0000        STOP        #$2700

******************
* code 0001
* MOVE.B
******************
code0001        STOP        #$2700

******************
* code 0010
* MOVE.L, MOVEA.L
******************
code0010        STOP        #$2700

******************
* code 0011
* MOVE.W, MOVEA.W
******************
code0011        STOP        #$2700

******************
* code 0100
* NOP, MOVEM, LEA, CLR, JSR, RTS
******************
code0100
    MOVE.L  nopex,D0        * move opcode word to D0
    MOVE.L  nopex,D1        * move opcode word to D1
    ANDI.L  #mask0806,D0    * mask bits 8-6
    ANDI.L  #mask1109,D0    * mask bits 11-9
    LSR.W   #6,D0           * shift D0 6 bits right
    LSR.W   #9,D1           * shift D1 9 bits right
    
******************
* Bits 08-06
* 000    * CLR.B
* 001    * NOP, CLR.W, RTS
* 010    * MOVEM.W, JSR, CLR.L
* 011    * MOVEM.L
* 111    * LEA
******************
    CMPI.W	#$0,D0
    BEQ.S	op_clr_b
    CMPI.W	#$1,D0
    BEQ.S	op_0100_001
    CMPI.W	#$2,D0
    BEQ.S	op_0100_010
    CMPI.W	#$3,D0
    BEQ.S	op_movem_l
    CMPI.W	#$7,D0
    BEQ.S	op_lea
    
op_clr_b
	CMPI.W	#$1,D1			* check rest of bits
	BNE		bad_op			* quit if bad
	LEA		str_clr_b,A1
	JSR		print			* print CLR.B
	JSR		next_word

op_0100_001
	
op_nop
op_clr_w
op_rts


op_0100_010
op_movem_w
op_jsr
op_clr_l


op_movem_l
op_lea
    
code5000
code5001    
code5010    
code5011    
code5111    

******************
* code 0101
* ADDQ
******************
code0101        STOP        #$2700

******************
* code 0110
* Bcc (BCC, BGT, BLE)
******************
code0110        STOP        #$2700

******************
* code 0111
* MOVEQ
******************
code0111        STOP        #$2700

******************
* code 1000
* DIVU, OR
******************
code1000        STOP        #$2700

******************
* code 1001
* SUB
******************
code1001
        JMP     print_data

******************
* code 1010
* NOT SUPPORTED
******************
code1010
        JMP     print_data

******************
* code 1011
* CMP
******************
code1011
        JMP     print_data

******************
* code 1100
* MULS, AND
******************
code1100
        JMP     print_data

******************
* code 1101
* ADD, ADDA
******************
code1101
        JMP     print_data

******************
* code 1110
* LSL, LSR, ASR, ASL, ROL, ROR
******************
code1110
        JMP     print_data

******************
* code 1111
* NOT SUPPORTED
******************
code1111
        JMP     print_data
        
******************
* Subroutine: chk_flag
* Checks the first word of D4.
*	0 - good
*	1 - fail at i/o
*	2 - fail at opcode
*	3 - fail at ea
******************     
chk_flag
		SWAP	D4
		CMPI.B	#0,D4
		BNE.S	fail
good
		SWAP	D4
		RTS
fail
		SWAP	D4
		BRA		print_data

******************
* Subroutine: bad_op
* If the opcode is not supported or garbage bits
******************
bad_op
		
		
***********************************************************
* Size subroutines
* Uses the latter word of D4
* Prints the size of the operation

******************
* Subroutine: size1
* Prints a dot + size
* 1 bit
*	W - 0
*	L - 1
******************
size1
		CMPI.B	#0,D4		* compare to 0
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
		CMPI.B	#0,D4		* compare to 0
		BEQ.S	size_b
		* branch to w
		CMPI.B	#1,D4		* compare to 1
		BEQ.S	size_w
		CMPI.B	#3,D4		* compare to 3
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
		CMPI.B	#0,D4		* compare to 0
		BEQ.S	size_b
		CMPI.B	#4,D4		* compare to 4
		BEQ.S	size_b
		* branch to w
		CMPI.B	#1,D4		* compare to 1
		BEQ.S	size_w
		CMPI.B	#3,D4		* compare to 3
		BEQ.S	size_w
		CMPI.B	#5,D4		* compare to 5
		BEQ.S	size_w
		* the rest is l
		BRA		size_l
		
******************
* Size printing subroutines
* Prints b/w/l
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
str_movem	DC.B	'MOVEM',0
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
str_b      DC.B    '.B',0
str_w      DC.B    '.W',0
str_l      DC.B    '.L',0

* Misc strings
space		DC.B	' ',0
dot			DC.B	'.',0

        END     $400 

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
