*-----------------------------------------------------------
* Title      :EA Template
* Written by :Khuzaima
* Date       :12/4
* Description:ALL OF EA
*-----------------------------------------------------------
    ORG    $1000
abs_word  EQU %0000000000000000  
abs_long  EQU %0000000000000001 
ime_data  EQU %0000000000000100   
maskDR    EQU %0000111000000000
mask1512  EQU     %1111000000000000
mask0806  EQU     %0000000111000000
mask05    EQU     %0000000000100000
mask08    EQU     %0000000100000000
mask10    EQU     %0000010000000000
mask1109  EQU     %0000111000000000
mask1108  EQU     %0000111100000000
mask0200  EQU     %0000000000000111
mask0503  EQU     %0000000000111000
mask0403  EQU     %0000000000011000
mask0706  EQU     %0000000011000000
shift6    EQU 6
shift3    EQU 3
base16    EQU 16
valid_d   EQU %00000001
valid_a   EQU %00000010
valid_ai  EQU %00000100
valid_aip EQU %00001000
valid_aim EQU %00010000
valid_aw  EQU %00100000
valid_alw EQU %01000000
valid_id  EQU %10000000

*************************************************************
*ValidEA is a Byte which shows which of the 8 EA are valid for
*a given instruction each bit represents an EA.
*Starting from the least significant bit.
*1st = Dn
*2nd = An
*3rd = (An)
*4th = (An)+
*5th = -(An)
*6th = (xxx).W
*7th = (xxx).L
*8th = #<Data>
*For each bit, 1 means is valid, 0 means is not valid. 
*
*************************************************************
***********************************************************
* conversion subroutines
* Converts D6 to ascii, and stores it in D7
*   D6: up to word length, number to convert
*   D7: converted number
* Please make sure that D7 is clear beforehand
******************

hex_to_ascii_w
    BSR.S   hex_to_ascii_b  * convert first byte
    LSR.W   #8,D6
    SWAP    D7              * make space for next byte
    BSR.S   hex_to_ascii_b  * convert second byte
    SWAP    D7              * put them in correcft order
    RTS   
    
hex_to_ascii_b
    MOVE.B  D6,D7
    LSR.B   #4,D7           * isolate first digit
    BSR.S   hex_to_ascii    * convert to ascii
    LSL.W   #8,D7           * put it on the left side
    MOVE.B  D6,D7
    AND.B  #%00001111,D7   * mask first bit out
    BSR.S   hex_to_ascii    * convert to ascii
    RTS    
    
hex_to_ascii
    CMPI.B  #9,D7
    BLE     no_to_ascii
    BRA     char_to_ascii
    
no_to_ascii
    ADD.B   #$30,D7
    RTS
   
char_to_ascii
    ADD.B   #$37,D7
    RTS


*************************************************************
* D5 == Mode
* D6 == Register
*************************************************************



START:                  ; first instruction of program
        LEA     $5000,A2
        ROL     $43AC
        MOVE.B  #%00000000,size
        LEA     $103A,A3
        MOVE.W  (A3)+,currWord
        JSR     ea_rol
        
    SIMHALT             ; halt simulator
*************************************************************
*Invalid ea: None
*mode-bits:3-5 reg-bits:0-2 size-bits:12-13
*************************************************************
ea_0500
              *Mask source mode
              MOVE.W        currWord,D5
              ANDI.W        #mask0503,D5
              LSR.W         #shift3,D5
              
              *Mask source Register
              MOVE.W        currWord,D6
              ANDI.W        #mask0200,D6
              
              
              *Use mode JMP Table
              LEA           mode_jmp,A0
              MULS          #6, D5
              JSR           0(A0,D5)  
              RTS
ea_1106
              *Mask Dest. mode
              MOVE.W        currWord,D5
              ANDI.W        #mask0806,D5
              LSR.W         #shift6,D5
    
              *Mask Dest. Register
              MOVE.W        currWord,D6
              ANDI.W        #mask1109,D6
              LSR.W         #shift6,D6
              LSR.W         #shift3,D6
    
              *Use mode JMP Table
              LEA           mode_jmp,A0
              MULS          #6, D5
              JSR           0(A0,D5)
              RTS

ea_move_src  
              MOVE.B  #%11111111,ValidEA
              JSR     ea_0500
              RTS

*************************************************************
*Invalid ea: An, #<data>
*mode-bits:6-8 reg-bits:9-11
*************************************************************
ea_move_dest  
              MOVE.B  #%01111101,ValidEA   
              JSR     ea_1106
              RTS

*************************************************************
*Invalid ea: None
*mode-bits:3-5 reg-bits:0-2 size-bits:12-13
*************************************************************
ea_movea
              MOVE.B  #%11111111,ValidEA
              JSR     ea_0500
              RTS
              
ea_moveq RTS
*************************************************************
*Invalid ea: Dn, An, #<Data>, (An)+
*mode-bits:3-5 reg-bits:0-2 size-bits:6 dr-bit:10 -> 0
*************************************************************
ea_movem_regmem
              MOVE.B  #%01110100,ValidEA
              JSR     ea_0500
              RTS

*************************************************************
*Invalid ea: Dn, An, #<Data>, -(An)
*mode-bits:3-5 reg-bits:0-2 size-bits:6 dr-bit:10 -> 0
*************************************************************
ea_movem_memreg
              MOVE.B  #%01101100,ValidEA
              JSR     ea_0500
              RTS

*************************************************************
*Invalid ea: Dn, An, #<Data>
*mode-bits:3-5 reg-bits:0-2 Opmode-bits:6-8
*Byte Word Long Operation
*000  001  010   < ea > + Dn ? Dn
*100  101  110   Dn + < ea > ? < ea > 
*************************************************************
ea_add_dest
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS
ea_add_src
              MOVE.B  #%11111111,ValidEA
              JSR     ea_0500
              RTS

*************************************************************
*Invalid ea: none
*mode-bits:3-5 reg-bits:0-2 Opmode-bits:6-8
*Opmode Field: 011-word operation 111-long opderation
*************************************************************
ea_adda
              MOVE.B  #%11111111,ValidEA
              JSR     ea_0500
              RTS

*************************************************************
*Invalid ea:An, #<Data>
*mode-bits:3-5 reg-bits:0-2 size-bits:6-7
*00-B 01-W 10-L
*************************************************************
ea_addi
              MOVE.B  #%01111101,ValidEA
              JSR     ea_0500
              RTS

ea_addq
              MOVE.B  #%01111111,ValidEA
              JSR     ea_0500
              RTS

ea_sub_dest
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS
ea_sub_src
              MOVE.B  #%11111111,ValidEA
              JSR     ea_0500
              RTS
ea_muls_src
              MOVE.B  #%11111101,ValidEA
              JSR     ea_0500
              RTS
              
ea_muls_dest
              MOVE.B  #%11111101,ValidEA
              JSR     ea_0500
              RTS

ea_divu
              MOVE.B  #%11111101,ValidEA
              JSR     ea_0500
              RTS

ea_lea
              MOVE.B  #%01100100,ValidEA
              JSR     ea_0500
              RTS
ea_clr
              MOVE.B  #%01111101,ValidEA
              JSR     ea_0500
              RTS

ea_and_dest
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS

ea_and_src
              MOVE.B  #%11111101,ValidEA
              JSR     ea_0500
              RTS

ea_or_dest
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS
ea_or_src
              MOVE.B  #%11111101,ValidEA
              JSR     ea_0500
              RTS
ea_lsl
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS
ea_asl
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS

ea_rol
              MOVE.B  #%01111100,ValidEA
              JSR     ea_0500
              RTS

ea_cmp
              MOVE.B  #%11111111,ValidEA
              JSR     ea_0500
              RTS
ea_jsr
              MOVE.B  #%01100100,ValidEA
              JSR     ea_0500
              RTS
              
mode_jmp   JMP   code0  *Dn - Data Register Direct
           JMP   code1  *An - Adress Register Direct
           JMP   code2  *(An) - Address Register Indirect
           JMP   code3  *(An)+ - Address Register Indirect with post increment 
           JMP   code4  *-(An) - Address Register Indirect with Pre Decrement
           JMP   code5  *Invalid
           JMP   code6  *Invalid
           JMP   code7  *(xxx).L || (xxx).W Absolute Adress || Immediate
           
*Dn - Data Register Direct
code0   MOVE.B     validEA,D5
        ANDI       #valid_d,D5
        CMPI       #valid_d,D5
        BNE        bad_ea
        MOVE.B     DReg,(A2)+
        JSR        hex_to_ascii_b
        MOVE.B     D7,(A2)+ 
        RTS
        
*An - Adress Register Direct
code1   MOVE.B     validEA,D5
        ANDI       #valid_a,D5
        CMPI       #valid_a,D5
        BNE        bad_ea
        MOVE.B     AReg,(A2)+
        JSR        hex_to_ascii_b
        MOVE.B     D7,(A2)+
        RTS
*(An) - Address Register Indirect
code2   MOVE.B     validEA,D5
        ANDI       #valid_ai,D5
        CMPI       #valid_ai,D5
        BNE        bad_ea
        MOVE.B     leftP,(A2)+ 
        MOVE.B     AReg,(A2)+
        JSR        hex_to_ascii_b
        MOVE.B     D7,(A2)+
        MOVE.B     rightP,(A2)+  
        RTS
        
*(An)+ - Address Register Indirect with post increment
code3   MOVE.B     validEA,D5
        ANDI       #valid_aip,D5
        CMPI       #valid_aip,D5
        BNE        bad_ea
        MOVE.B     leftP,(A2)+ 
        MOVE.B     AReg,(A2)+
        JSR        hex_to_ascii_b
        MOVE.B     D7,(A2)+
        MOVE.B     rightP,(A2)+  
        MOVE.B     plus,(A2)+
        RTS
        
*-(An) - Address Register Indirect with Pre Decrement 
code4   MOVE.B     validEA,D5
        ANDI       #valid_aim,D5
        CMPI       #valid_aim,D5
        BNE        bad_ea
        MOVE.B     minus,(A2)+
        MOVE.B     leftP,(A2)+ 
        MOVE.B     AReg,(A2)+
        JSR        hex_to_ascii_b
        MOVE.B     D7,(A2)+
        MOVE.B     rightP,(A2)+  
        RTS
        
code5   JMP bad_ea
        RTS

code6   JMP bad_ea
        RTS

*(xxx).L || (xxx).W || Absolute Adress
code7   CMPI.B      #abs_word,D6
        BEQ         abs_word_a
        CMPI.B      #abs_long,D6
        BEQ         abs_long_a
        CMPI.B      #ime_data,D6
        BEQ         ime_data_a
        BNE         bad_ea
        
abs_word_a    
        MOVE.B     validEA,D5
        ANDI       #valid_aw,D5
        CMPI       #valid_aw,D5
        BNE         bad_ea
        MOVE.B      hex_sign,(A2)+
        MOVE.W      (A3)+,D6
        BSR         h2a_w
        RTS

abs_long_a
        MOVE.B     validEA,D5
        ANDI       #valid_alw,D5
        CMPI       #valid_alw,D5
        BNE         bad_ea
        MOVE.B      hex_sign,(A2)+
        MOVE.L      (A3)+,D6
        BSR         h2a_l
        RTS

ime_data_a
        MOVE.B     validEA,D5
        ANDI       #valid_id,D5
        CMPI       #valid_id,D5
        BNE         bad_ea
        CMPI.B      #%00000000,size
        BEQ         ime_data_b
        CMPI.B      #%00000001,size
        BEQ         ime_data_w
        CMPI.B      #%00000010,size
        BEQ         ime_data_l
        BNE         bad_ea
        RTS
        

ime_data_b
        MOVE.B      ime_sign,(A2)+
        MOVE.B      hex_sign,(A2)+
        MOVE.W      (A3)+,D6
        BSR         h2a_b
        RTS

ime_data_w
        MOVE.B      ime_sign,(A2)+
        MOVE.B      hex_sign,(A2)+
        MOVE.W      (A3)+,D6
        BSR         h2a_w
        RTS
        
ime_data_l
        MOVE.B      ime_sign,(A2)+
        MOVE.B      hex_sign,(A2)+
        MOVE.L      (A3)+,D6
        BSR         h2a_l
        RTS
     
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
    
******************
* Opcode helper subroutines
* hex to ascii, but with load to buffer
******************
h2a_l
	SWAP	D6				* to get first word
	BSR		h2a_w
	SWAP	D6				* to get second word
	BSR		h2a_w
	RTS
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
        
bad_ea   MOVE.B	#3,D4			* set flag for bad opcode
         RTS

* Put variables and constants here
plus        DC.B        '+',0
minus       DC.B        '-',0
DReg        DC.B        'D',0
leftP       DC.B        '(',0
rightP      DC.B        ')',0
AReg        DC.B        'A',0
comma       DC.B        ', ',0
hex_sign    DC.B        '$',0
ime_sign    DC.B        '#',0
validEA     DC.B        0
sizeEA      DC.W        0
currWord    DC.B        0
buffTemp	DS.L	2
count		DS.B	1		* counter
size		DS.B	1		* size for EA

    END    START        ; last line of source




