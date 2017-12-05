*-----------------------------------------------------------
* Title      : Disassembler opcode
* Written by : Evelyn Mahasin
* Date       : 11/16/2017
* Description: 
*-----------------------------------------------------------

* Opcode equates

stack           EQU     $A000
*ex				EQU		%0101101000111111
ex				EQU		%0111101011111111
mask1512        EQU     %1111000000000000
mask0806        EQU     %0000000111000000
mask05          EQU     %0000000000100000
mask08          EQU     %0000000100000000
mask10          EQU     %0000010000000000
mask1109        EQU     %0000111000000000
mask1108        EQU     %0000111100000000
mask0200        EQU     %0000000000000111
mask0503        EQU     %0000000000111000
mask0403        EQU     %0000000000011000
mask0706        EQU     %0000000011000000
mask0700		EQU		$FF
               
*****************************************************************************************************************************************************
* Opcode part starts here
* D0 = opcode parts
* D1 = opcode parts
* A1 = message
* A2 = buffer ptr
*****************
    ORG     $1000
start
opcode
	MOVE.W	#ex,currWord	* load test

	LEA     buffer,A2       * load buffer address/init buffer ptr
	LEA		memPtr,A3		* load moving ptr to A3
	ADDQ.L	#4,A3			* move memPtr forward 1 word
	LEA     stack,SP        * Load the SP
	LEA     jmp_table,A0    * Index into the table
	CLR.L   D0              * Zero it
    MOVE.W  currWord,D0		* We'll play with it here
    LSR.W   #7,D0
    LSR.W   #5,D0           * shift 12 bits to the right
    MULU    #6,D0           * Form offset     
    JSR     0(A0,D0)        * Jump indirect with index
    MOVE.B	#0,(A2)			* end buffer with 0
    STOP	#$2700			* stop for now
        
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
	MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
	
    ANDI.W  #mask1108,D0    * mask bits 11-8
    LSR.W   #8,D0			* shift D0 8 bits right
    
    ANDI.W  #mask0706,D1    * mask bits 7-6
    LSR.W   #6,D1           * shift D1 6 bits right
    
    CMPI.B	#3,D1			* check that size field is valid
    BEQ		bad_op			* if equal, bad opcode
op_addi
    CMPI.B	#6,D0			* check rest of bits
    BNE		bad_op			* if not equal, bad opcode
    LEA		str_addi,A1
    BSR		print			* load str ADDI to buffer
    BSR		size2			* handle size
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    
    * loads source to buffer
    MOVE.B  pound,(A2)+		* load a # to buffer
    MOVE.B	dol,(A2)+		* load a $ to buffer
    CMPI.B	#0,D1			* byte 
    BRA		addi_byte
    CMPI.B	#1,D1			* word
    BRA		addi_word
    CMPI.B	#2,D1			* long
    BRA		addi_long
    
addi_byte
	ADDQ.L	#2,A3			* move memPtr forward 1 byte
	MOVE.B	(A3)+,D6
	BSR		h2a_b			* load to buffer
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_addi			* load EA to buffer
	RTS
addi_word
	MOVE.W	(A3)+,D6
	BSR		h2a_w			* load to buffer
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_addi			* load EA to buffer
	RTS
addi_long
    MOVE.L	(A3)+,D6
	BSR		h2a_l			* load to buffer
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_addi			* load EA to buffer
    RTS

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
    
    BSR		ea_move_src		* load EA to buffer
    MOVE.B  comma,(A2)+		* load a comma to buffer
    BSR		ea_move_dest	* load EA to buffer
    
    RTS

******************
* code 0010
* MOVE.L, MOVEA.L
******************
code0010
	MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D6			* move opcode word to D6
    
    ANDI.W  #mask0806,D0    * mask bits 8-6
    LSR.W   #6,D0           * shift D0 6 bits right
    CMPI.B	#1,D0			* if 1, is MOVEA.L
    BNE.S	op_move_l		* if not, is MOVE.L
op_movea_l
	LEA		str_movea,A1
    BSR		print			* load str MOVEA to buffer
    BSR		size_l			* load .L to buffer
    LEA		space3,A1
    BSR		print			* load 3 spaces to buffer
    
    BSR		ea_movea_src	* load EA to buffer
    MOVE.B  comma,(A2)+		* load a comma to buffer
    MOVE.B  str_a,(A2)+		* load A to buffer
    BSR		print_reg		* print register number
    RTS
op_move_l
	LEA		str_move,A1
    BSR		print			* load str MOVE to buffer
    BSR		size_l			* load .L to buffer
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    
    BSR		ea_move_src		* load EA to buffer
    MOVE.B  comma,(A2)+		* load a comma to buffer
    BSR		ea_move_dest	* load EA to buffer
    RTS
    
******************
* code 0011
* MOVE.W, MOVEA.W
******************
code0011
	MOVE.W  currWord,D0     * move opcode word to D0
	MOVE.W	D0,D6			* move opcode word to D6
	
    ANDI.W  #mask0806,D0    * mask bits 8-6
    LSR.W   #6,D0           * shift D0 6 bits right
    CMPI.B	#1,D0			* if 1, is MOVEA.W
    BNE.S	op_move_w		* if not, is MOVE.W
op_movea_w
	LEA		str_movea,A1
    BSR		print			* load str MOVEA to buffer
    BSR		size_w			* load .W to buffer
    LEA		space3,A1
    BSR		print			* load 3 spaces to buffer
    
    BSR		ea_movea_src	* load EA to buffer
    MOVE.B  comma,(A2)+		* load a comma to buffer
    MOVE.B  str_a,(A2)+		* load A to buffer
    BSR		print_reg		* print register number
    RTS
op_move_w
	LEA		str_move,A1
    BSR		print			* load str MOVE to buffer
    BSR		size_w			* load .W to buffer
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    
    BSR		ea_move_src		* load EA to buffer
    MOVE.B  comma,(A2)+		* load a comma to buffer
    BSR		ea_move_dest	* load EA to buffer
    RTS
    
************************************************************************
* code 0100
* NOP, MOVEM, LEA, CLR, JSR, RTS
************************************************************************
code0100
    MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
    
    ANDI.W  #mask0806,D0    * mask bits 8-6
    LSR.W   #6,D0           * shift D0 6 bits right

    ANDI.W  #mask1109,D1    * mask bits 11-9 
    LSR.W   #8,D1
    LSR.W   #1,D1           * shift D1 9 bits right
    
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
	LEA		space5,A1
    BSR		print			* load 5 spaces to buffer
    BSR		ea_clr			* print ea param
	RTS

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
	BSR		ea_clr			* print ea param
	RTS
	
nop_or_rts
    MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
    
    ANDI.W  #mask0200,D0    * mask bits 2-0

    ANDI.W  #mask0503,D1    * mask bits 5-3.
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
	RTS
op_rts
    CMPI.B  #6,D1           * check rest of bits
    BNE     bad_op          * if bad
	LEA		str_rts,A1
	BSR		print			* load RTS to buffer
	RTS

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
	
	* handle params, prep D0 & D1
	MOVE.W	(A3)+,D1		* load next word (reg list mask)
	
	MOVE.W  currWord,D0		* move opcode word to D0
	ANDI.W	#mask10,D0		* mask bit 10
	LSR.W   #8,D0
	LSR.W   #2,D0           * shift 10 bits right

	TST.B	D0				* regmem, else memreg
	BEQ		movem_regmem
	
* A7-A0/D7-D0
movem_memreg
	BSR		ea_movem_memreg	* load EA to buffer
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		loop_start		* load list to buffer
	RTS
* D0-D7/A0-A7
movem_regmem
	BSR		loop_start		* load list to buffer
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_movem_regmem	* load EA to buffer
	RTS
	
* pretty list printing
* instead of 		MOVEM.L (A0)+,D0/D1/D2/A4/A3/A0/A1
* I'm gonna print 	MOVEM.L (A0)+,D0-D2/A0-A4
* bear with me.
* a byte of D0 holds direction
* a word of D1 holds reg list
* count is loop count
* reg_count is the reg you want to print
* last_reg is the last reg that was set
* last_count is the value of the bit before
load_list
	MOVE.B	#0,count		* init counter
loop_start
	MOVE.B	#0,count		* init counter
	BSR		rotate
	BCS		loop_trans		* found a starting reg
	
	ADDI.B	#1,count		* count++
	BRA		loop_start		* haven't found a starting reg
loop_trans
	MOVE.B	count,reg_count
	BSR		reg_print		* print starting reg
	MOVE.B	count,last_reg	* set last reg
	MOVE.B	#1,last_count	* set last count
	ADDI.B	#1,count		* count++
loop_mid
	CMPI.B	#15,count		* check if we still need to loop
	BGT		loop_end		* no more
	BSR		rotate			* if set
	BCC		loop_mid_else	* else
loop_mid_if
	TST.B	last_count		* if last count 0
	BEQ		loop_mid_set	* print '/<reg>'
	
	ADDI.B	#1,count		* count++
	MOVE.B	#1,last_count	* set last count 1
	BRA		loop_mid
loop_mid_set
	MOVE.B  slash,(A2)+		* load a / to buffer
	MOVE.B	count,reg_count
	BSR		reg_print		* print reg
	MOVE.B	count,last_reg	* set last reg
	
	ADDI.B	#1,count		* count++
	MOVE.B	#1,last_count	* set last count 1
	BRA		loop_mid
loop_mid_else
	TST.B	last_count		* if last count 1
	BNE		loop_mid_clear	* print '-<reg>' or nothing
	
	ADDI.B	#1,count		* count++
	MOVE.B	#0,last_count	* set last count 0
	BRA		loop_mid
loop_mid_clear
	MOVE.B	count,D6		* move to D6 for a while
	SUBI.B	#1,D6			* count - 1 (ending reg)
	* if last printed reg was not the ending reg,
	* print the ending reg (-<reg>).
	* if not, print nothing
	CMP.B	last_reg,D6
	BEQ		loop_mid_clear_end
	
	MOVE.B  dash,(A2)+		* load a - to buffer
	MOVE.B	count,reg_count
	BSR		reg_print		* print reg
loop_mid_clear_end
	ADDI.B	#1,count		* count++
	MOVE.B	#0,last_count	* set last count 0
	BRA		loop_mid
loop_end
	RTS
	
* rotate based on direction in D0 byte
rotate
	TST.B	D0				* rotate right if memreg
	BEQ		rotate_left		* left if regmem
	ROR		#1,D1			* rotate right once, into carry bit
	RTS
rotate_left
	ROL		#1,D1			* rotate left once, into carry bit
	RTS
	
* print reg in reglist based on count in reg_count
reg_print
	TST.B	D0				* rotate right if memreg
	CMPI.B	#8,reg_count	* compare regcount
	BLE		reg_data		* its a dreg
reg_addr
	MOVE.B  str_a,(A2)+		* load A to buffer
	MOVE.B	reg_count,D6	* prepare to print
	SUBI.B	#8,D6			* correct reg num
	BSR		h2a_reg			* load byte to buffer
	RTS
reg_data
	MOVE.B  str_d,(A2)+		* load D to buffer
	MOVE.B	reg_count,D6	* prepare to print
	BSR		h2a_reg			* load byte to buffer
	RTS
* movem stuff done

op_jsr
	LEA		str_jsr,A1
	BSR		print			* load JSR to buffer
	LEA		space7,A1
	BSR		print			* print 7 spaces
	BSR		ea_jsr			* print ea param
	RTS
op_clr_l
	LEA		str_clr,A1
	BSR		print			* load CLR to buffer
	BSR		size_l			* load .L to buffer
	LEA		space5,A1
	BSR		print			* print 5 spaces
	BSR		ea_clr			* print ea param
	RTS

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
	
	* handle params
	MOVE.W  currWord,D0		* move opcode word to D0
	ANDI.W	#mask10,D0		* mask bit 10
	LSR.W   #8,D0
	LSR.W   #2,D0           * shift 10 bits right
	
	TST.B	D0				* regmem, else memreg
	BEQ		movem_regmem
	BRA		movem_memreg

******************
* Bits 08-06
* 111 - LEA
******************
op_lea
    LEA		str_lea,A1
	BSR		print			* load LEA to buffer
	LEA		space7,A1
	BSR		print			* print 7 spaces
	
	BSR		ea_lea			* load EA to buffer
    MOVE.B  comma,(A2)+		* load a comma to buffer
    MOVE.B  str_a,(A2)+		* load A to buffer
    BSR		print_reg		* print register number
    RTS
************************************************************************

******************
* code 0101
* ADDQ
******************
code0101
    MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W  D0,D1    		* move opcode word to D1
    MOVE.W  D0,D6    		* move opcode word to D6

    ANDI.W  #mask08,D0		* mask bit 8
    TST.W	D0				* bit 8 should be 0
    BNE		bad_op			* BAD! BAD OP! HISS
op_addq
    LEA		str_addq,A1
	BSR		print			* load ADDQ to buffer
	
    ANDI.W  #mask0706,D1    * mask bits 7-6
    LSR.W   #6,D1           * shift D1 6 bits right
    
    CMPI.B	#3,D1			* check that size field is valid
    BEQ		bad_op			* if equal, bad opcode
    
    BSR		size2			* handle size
    LEA		space4,A1
    BSR		print			* load 4 spaces to buffer
    
    MOVE.B  pound,(A2)+		* load a # to buffer
    
    ANDI.W  #mask1109,D6    * mask bits 11-9 for address reg
    LSR.W   #8,D6
    LSR.W   #1,D6           * shift D6 9 bits right
    TST.B	D6				* if 0
    BEQ		print8			* print 8
    BSR		h2a_b			* load address reg to buffer
    BRA.S	addq_ea			* print ea part
print8
	MOVE.B  eight,(A2)+		* load an 8 to buffer
addq_ea
	BSR		ea_addq			* load EA to buffer
	RTS

******************
* code 0110
* Bcc (BCC, BGT, BLE)
******************
code0110
	MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
	
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
	BSR		bcc_size		* deal with size + spaces
	RTS
op_bcc
	LEA		str_bcc,A1
	BSR		print			* load BCC to buffer
	BRA		bcc_size		* deal with size + spaces
op_bgt
	LEA		str_bgt,A1
	BSR		print			* load BGT to buffer
	BRA		bcc_size		* deal with size + spaces
	
* Bcc size subroutine, using D1 containing last 8 bits
bcc_size
	LEA		space7,A1
	BSR		print			* print 7 spaces
	TST.B	D1				* if displacement byte is 0
	BEQ.S	bcc_w			* it is .W
bcc_s
	MOVE.L	memPtrGood,D6	* move current address to D6
	ADD.L	D1,D6			* add the displacement to address
	BSR		h2a_l			* print the displaced address
	RTS
bcc_w
	MOVE.L	memPtrGood,D6	* move current address to D6
	MOVE.W	(A3)+,D1		* load next word to D1
	ADD.L	D1,D6			* add the displacement to address
	BSR		h2a_l			* print the displaced address
	RTS

******************
* code 0111
* MOVEQ
******************
code0111
	MOVE.W  currWord,D0     * move opcode word to D0
	MOVE.W	D0,D6			* move data to D6
	
    ANDI.W  #mask08,D0		* mask bit 8
	TST.W	D0				* should all be 0
	BNE		bad_op			* bad if not
	LEA		str_moveq,A1
	BSR		print			* load MOVEQ to buffer
	LEA		space5,A1
	BSR		print			* print 5 spaces
	
	MOVE.B  pound,(A2)+		* load a # to buffer
	BSR		h2a_b			* load data into buffer
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	
	RTS

******************
* code 1000
* DIVU, OR
******************
code1000
	MOVE.W  currWord,D0     * move opcode word to D0
	MOVE.W	D0,D6			* move data to D6
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
******************
* <ea> V Dn -> Dn - 000,001,010
* Dn V <ea> -> <ea> - 100,101,110
******************
	* branch to src
	TST.B	D1			* compare to 0
	BEQ		op_or_src
	CMPI.B	#1,D1		* compare to 1
	BEQ		op_or_src
	CMPI.B	#2,D1		* compare to 2
	BEQ		op_or_src
* the rest is dest    
op_or_dest
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_or_dest		* handle ea
	RTS
op_or_src
	BSR		ea_or_src		* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	RTS
    
op_divu
	LEA		str_divu,A1
	BSR		print			* load DIVU to buffer
	LEA		space6,A1
	BSR		print			* print 6 spaces
	
	BSR		ea_divu			* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	
	RTS

******************
* code 1001
* SUB
******************
code1001
	MOVE.W  currWord,D0     * move opcode word to D0
	MOVE.W	D0,D6			* move data to D6
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
******************
* <ea> - Dn -> Dn - 000,001,010
* Dn - <ea> -> <ea> - 100,101,110
******************
	* branch to src
	TST.B	D1			* compare to 0
	BEQ		op_sub_src
	CMPI.B	#1,D1		* compare to 1
	BEQ		op_sub_src
	CMPI.B	#2,D1		* compare to 2
	BEQ		op_sub_src
* the rest is dest    
op_sub_dest
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_sub_dest		* handle ea
	RTS
op_sub_src
	BSR		ea_sub_src		* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	RTS

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
    MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
    MOVE.W	D0,D6			* move data to D6
    
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
	
	BSR		ea_cmp			* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	
	RTS

******************
* code 1100
* MULS, AND
******************
code1100
	MOVE.W  currWord,D0     * move opcode word to D0
	MOVE.W	D0,D6			* move data to D6
    ANDI.W  #mask0806,D0	* mask bits 8-6
    LSR.W   #6,D0			* shift D0 6 bits right
    
    CMPI.B	#7,D0			* MULS case
    BEQ		op_muls
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
******************
* <ea> ^ Dn -> Dn - 000,001,010
* Dn ^ <ea> -> <ea> - 100,101,110
******************
	* branch to src
	TST.B	D1			* compare to 0
	BEQ		op_and_src
	CMPI.B	#1,D1		* compare to 1
	BEQ		op_and_src
	CMPI.B	#2,D1		* compare to 2
	BEQ		op_and_src
* the rest is dest    
op_and_dest
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_and_dest		* handle ea
	RTS
op_and_src
	BSR		ea_and_src		* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	RTS
	
op_muls
	LEA		str_muls,A1
	BSR		print			* load MULS to buffer
	LEA		space6,A1
	BSR		print			* print 6 spaces
	
	BSR		ea_muls			* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	
	RTS

******************
* code 1101
* ADD, ADDA
******************
code1101
	MOVE.W  currWord,D1     * move opcode word to D1
	MOVE.W	D1,D6			* move data to D6
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
******************
* <ea> + Dn -> Dn - 000,001,010
* Dn + <ea> -> <ea> - 100,101,110
******************
	* branch to src
	TST.B	D1			* compare to 0
	BEQ		op_add_src
	CMPI.B	#1,D1		* compare to 1
	BEQ		op_add_src
	CMPI.B	#2,D1		* compare to 2
	BEQ		op_add_src
* the rest is dest    
op_add_dest
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	MOVE.B  comma,(A2)+		* load a comma to buffer
	BSR		ea_add_dest		* handle ea
	RTS
op_add_src
	BSR		ea_add_src		* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_d,(A2)+		* load D to buffer
	BSR		print_reg		* print register no
	RTS

op_adda
	LEA		str_adda,A1
	BSR		print			* load ADDA to buffer
	BSR		size3			* handle size printing
	LEA		space4,A1
	BSR		print			* print 4 spaces
	
	BSR		ea_adda			* handle ea
	MOVE.B  comma,(A2)+		* load a comma to buffer
	MOVE.B  str_a,(A2)+		* load A to buffer
	BSR		print_reg		* print register no
	
	RTS

******************
* code 1110
* LSL, LSR, ASR, ASL, ROL, ROR
******************
code1110
	MOVE.W  currWord,D0		* move opcode word to D0
    MOVE.W	D0,D1			* move opcode word to D1
    MOVE.W	D0,D6			* move opcode word to D6
	
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
    
    CMPI.B	#0,D0
    BRA		op_asd			* ASd case
    CMPI.B	#1,D0
    BRA		op_lsd			* LSd case
    
	* ROd case left
	CMPI.B	#3,D0			* ensure correct op
	BNE		bad_op			* bad case
	MOVE.W  currWord,D0     * move opcode word to D0
	ANDI.W  #mask08,D0		* mask bit 8
	TST.W	D0				* right dir
	BNE.S	op_rol
op_ror
	LEA		str_ror,A1
	BSR		print			* print ROR
	BRA		sr_end
op_rol
	LEA		str_rol,A1
	BSR		print			* print ROL
	BRA		sr_end
op_asd
	MOVE.W  currWord,D0     * move opcode word to D0
	ANDI.W  #mask08,D0		* mask bit 8
	TST.W	D0				* right dir
	BNE.S	op_asl
op_asr
	LEA		str_asr,A1
	BSR		print			* print ASR
	BRA		sr_end
op_asl
	LEA		str_asl,A1
	BSR		print			* print ASL
	BRA		sr_end
op_lsd
	MOVE.W  currWord,D0     * move opcode word to D0
	ANDI.W  #mask08,D0		* mask bit 8
	TST.W	D0				* right dir
	BNE.S	op_lsl
op_lsr
	LEA		str_lsr,A1
	BSR		print			* print LSR
	BRA		sr_end
op_lsl
	LEA		str_lsl,A1
	BSR		print			* print LSL
	BRA		sr_end
sr_end
	BSR		size2			* handle size
	LEA		space5,A1
	BSR		print			* print 5 spaces
	MOVE.W  currWord,D0     * move opcode word to D0
	ANDI.W  #mask05,D0		* mask bit 5 (i/r field)
	LSR.W   #5,D0			* shift D0 5 bits right
	TST.B	D0
	BEQ		sr_imd		* imediate src if i/r field 0
* else, register src
sr_reg
	MOVE.B	str_d,(A2)+		* load D to buffer
	BSR		print_reg		* load reg no to buffer
	MOVE.B	comma,(A2)+		* load comma to buffer
	BRA		sr_dest
sr_imd
	MOVE.B	pound,(A2)+		* load # to buffer
	BSR		print_reg		* load reg no to buffer
	MOVE.B	comma,(A2)+		* load comma to buffer
	BRA		sr_dest
* print destination data reg
sr_dest
	MOVE.B	str_d,(A2)+		* load D to buffer
	MOVE.W  currWord,D6     * move opcode word to D6
	LSL.W	#8,D6
	LSL.W	#1,D6			* shift D6 9 bits left
	BSR		print_reg		* load reg no to buffer
	RTS
	
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
	LEA     jmp_table_1110,A0	* Index into the table
	ANDI.W  #mask1108,D0	* mask bits 11-8
    LSR.W   #8,D0			* shift D0 8 bits right
    MULU    #6,D0			* Form offset     
    JSR     0(A0,D0)        * Jump indirect with index
    
jmp_table_1110
	JMP		op_asr_m
	JMP		op_asl_m
	JMP		op_lsr_m
	JMP		op_lsl_m
	JMP		op_roxr_m
	JMP		op_roxl_m
	JMP		op_ror_m
	JMP		op_rol_m

op_asr_m
	LEA		str_asr,A1
	BSR		print			* load ASR to buffer
	BRA		op_asd_m
op_asl_m
	LEA		str_asl,A1
	BSR		print			* load ASL to buffer
	BRA		op_asd_m
op_asd_m
	LEA		space7,A1
	BSR		print			* prints 7 spaces
	BSR		ea_asd			* handle ea
	RTS
op_lsr_m
	LEA		str_lsr,A1
	BSR		print			* load LSR to buffer
	BRA		op_lsd_m
op_lsl_m
	LEA		str_lsl,A1
	BSR		print			* load LSL to buffer
	BRA		op_lsd_m
op_lsd_m
	LEA		space7,A1
	BSR		print			* prints 7 spaces
	BSR		ea_lsd			* handle ea
	RTS
op_roxr_m
op_roxl_m
	BRA		bad_op			* not supported
op_ror_m
	LEA		str_ror,A1
	BSR		print			* load ROR to buffer
	BRA		op_rod_m
op_rol_m
	LEA		str_rol,A1
	BSR		print			* load ROL to buffer
	BRA		op_rod_m
op_rod_m
	LEA		space7,A1
	BSR		print			* prints 7 spaces
	BSR		ea_rod			* handle ea
	RTS

******************
* code 1111
* NOT SUPPORTED
******************
code1111
    BRA     bad_op			* not supported
    
* end of opcodes
*****************************************************************************************************************************************************
*************************************************************
*Invalid ea: None
*mode-bits:3-5 reg-bits:0-2 size-bits:12-13
*************************************************************
ea_move_src  RTS

*************************************************************
*Invalid ea: An, #<data>
*mode-bits:6-8 reg-bits:9-11
*************************************************************
ea_move_dest RTS

*************************************************************
*Invalid ea: None
*mode-bits:3-5 reg-bits:0-2 size-bits:12-13
*************************************************************
ea_movea_src RTS

*************************************************************
*Invalid ea: Dn, An, #<Data>, (An)+
*mode-bits:3-5 reg-bits:0-2 size-bits:6 dr-bit:10 -> 0
*************************************************************
ea_movem_regmem  RTS

*************************************************************
*Invalid ea: Dn, An, #<Data>, -(An)
*mode-bits:3-5 reg-bits:0-2 size-bits:6 dr-bit:10 -> 0
*************************************************************
ea_movem_memreg  RTS

*************************************************************
*Invalid ea: Dn, An, #<Data>
*mode-bits:3-5 reg-bits:0-2 Opmode-bits:6-8
*Byte Word Long Operation
*000  001  010   < ea > + Dn ? Dn
*100  101  110   Dn + < ea > ? < ea > 
*************************************************************
ea_add_dest
	RTS
ea_add_src
	RTS

*************************************************************
*Invalid ea: none
*mode-bits:3-5 reg-bits:0-2 Opmode-bits:6-8
*Opmode Field: 011-word operation 111-long opderation
*************************************************************
ea_adda  RTS

*************************************************************
*Invalid ea:An, #<Data>
*mode-bits:3-5 reg-bits:0-2 size-bits:6-7
*00-B 01-W 10-L
*************************************************************
ea_addi  RTS

ea_addq	 RTS

ea_sub_dest
	RTS
ea_sub_src
	RTS
ea_muls  RTS

ea_divu  RTS

ea_lea   RTS

ea_clr   RTS

ea_and_dest
	RTS
ea_and_src
	RTS
ea_or_dest
	RTS
ea_or_src
	RTS
ea_lsd   RTS

ea_asd   RTS

ea_rod   RTS

ea_cmp   RTS

ea_jsr   RTS
        
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
* Update flag, then call IO's print line
******************
bad_op
	MOVE.B	#2,D4			* set flag for bad opcode
    RTS

******************
* Subroutine: print_data TEMPORARY
******************
print_data
    STOP	#$2700
    
******************
* Subroutine: print
* Prints the 0 terminated string
* put address to data in A1
******************
print
print_loop
    MOVE.B  (A1)+,(A2)+     * move a byte, and progress both pointers
print_main
	TST.B	(A1)        	* check if we hit 00
	BNE     print_loop      * if not, push next byte to buffer
    RTS
    
******************
* Subroutine: print_byte
* Loads a byte in A1 to buffer
******************
print_byte
	MOVE.B  (A1)+,(A2)+     * move a byte, and progress both pointers
	RTS
    
******************
* Subroutine: print_word
* Loads a word in A1 to buffer
******************
print_word
	MOVE.B	#0,count		* initialize counter
print_word_loop
    MOVE.B  (A1)+,(A2)+     * move a byte, and progress both pointers
    ADD.B	#1,count		* increase counter
print_word_main
	CMPI.B  #2,count        * check if we hit 00
	BNE     print_word_loop * if not, push next byte to buffer
    RTS
    
******************
* Subroutine: print_long
* Loads a long in A1 to buffer
******************
print_long
	MOVE.B	#0,count		* initialize counter
print_long_loop
    MOVE.B  (A1)+,(A2)+     * move a byte, and progress both pointers
    ADD.B	#1,count		* increase counter
print_long_main
	CMPI.B  #4,count        * check if we hit 00
	BNE     print_long_loop * if not, push next byte to buffer
    RTS
        
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
* Prints b/w/l/s, then sets the flag
******************
size_b
	MOVE.B	dot,(A2)+
	MOVE.B	str_b,(A2)+	* size is b
	BRA		set_b
size_w
	MOVE.B	dot,(A2)+
	MOVE.B	str_w,(A2)+	* size is w
	BRA		set_w
size_l
	MOVE.B	dot,(A2)+
	MOVE.B	str_l,(A2)+	* size is l
	BRA		set_l
	
******************
* Size flag setting subroutines
* Sets flag size for b/w/l/s
******************
set_b
	MOVE.B	#0,size		* set size flag b
	RTS
set_w
	MOVE.B	#1,size		* set size flag w
	RTS
set_l
	MOVE.B	#2,size		* set size flag l
	RTS

******************
* Subroutine: print register
* Prints register number in bits 11-9
* Load currword into D6 prior to calling this SR
******************
print_reg
	ANDI.W  #mask1109,D6    * mask bits 11-9 for address reg
    LSR.W   #8,D6
    LSR.W   #1,D6           * shift D6 9 bits right
    BSR		h2a_reg			* load address reg to buffer
    RTS

******************
* Opcode helper subroutines
* hex to ascii, but with load to buffer
******************
h2a_l
	SWAP	D6				* to get first word
	BSR		h2a_w
	SWAP	D6				* to get second word
	BRA		h2a_w
h2a_w
	BSR		hex_to_ascii_w	* convert
	MOVE.L	D7,buffTemp		* load to buffTemp
	LEA		buffTemp,A1
	BSR		print_long		* load to buffer
	RTS
h2a_b
	BSR		hex_to_ascii_b	* convert
	MOVE.W	D7,buffTemp		* load to buffTemp
	LEA		buffTemp,A1
	BSR		print_word		* load to buffer
	RTS
h2a_reg
	BSR		hex_to_ascii_b	* convert
	MOVE.B	D7,buffTemp		* load to buffTemp
	LEA		buffTemp,A1
	BSR		print_byte		* load to buffer
	RTS

***********************************************************
* conversion subroutines
* Converts D6 to ascii, and stores it in D7
*   D6: up to word length, number to convert
*   D7: converted number
* Please make sure that D7 is clear beforehand
* l version loads to buffer, others don't
******************	
hex_to_ascii_w
    BSR.S   hex_to_ascii_b  * convert second byte
    LSR.W   #8,D6
    SWAP    D7              * make space for first byte
    BSR.S   hex_to_ascii_b  * convert first byte
    SWAP    D7              * put them in correct order
    RTS   
    
hex_to_ascii_b
    MOVE.B  D6,D7
    LSR.B   #4,D7           * isolate first digit
    BSR.S   hex_to_ascii    * convert to ascii
    LSL.W   #8,D7           * put it on the left side
    MOVE.B  D6,D7
    AND.B   #%00001111,D7   * mask first bit out
    BSR.S   hex_to_ascii    * convert to ascii
    RTS    
    
hex_to_ascii
    CMPI.B  #9,D7
    BGT     char_to_ascii
no_to_ascii
    ADD.B   #$30,D7
    RTS
char_to_ascii
    ADD.B   #$37,D7
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
str_b		DC.B    'B'
str_w       DC.B    'W'
str_l       DC.B    'L'

* Misc strings
space1		DC.B	' ',0
space2		DC.B	'  ',0
space3		DC.B	'   ',0
space4		DC.B	'    ',0
space5		DC.B	'     ',0
space6		DC.B	'      ',0
space7		DC.B	'       ',0
comma		DC.B	','
pound		DC.B	'#'
dol			DC.B	'$'
eight		DC.B	'8'
dot			DC.B	'.'
slash		DC.B	'/'
dash		DC.B	'-'

* EA strings
str_d		DC.B	'D'
str_a		DC.B	'A'
str_lp		DC.B	'('
str_rp		DC.B	')'

* Variables
buffer      DS.B    50      * 10b for memory, 10b for opcode
count		DS.B	1		* counter
currWord	DS.W	1		* current word
size		DS.B	1		* size for EA
memPtr      DS.L    1       * moving ptr
memPtrGood  DS.L    1       * address to print
buffTemp	DS.L	2		* workaround for loading h2a to buff

* MOVEM vars
last_count	DS.B	1		* holds last count bit's value
last_reg	DS.B	1		* holds last printed reg's count
reg_count	DS.B	1		* holds count to be reg_printed

        	END     start







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
