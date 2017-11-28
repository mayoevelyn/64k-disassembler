*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
*-----------------------------------------------------------
* DEFINE
*-----------------------------------------------------------
    ORG    $1000
CR              EQU     $0D         * carriage return
LF              EQU     $0A         * line feed
user_input      EQU     $670
min_addr        EQU     $00006000
max_addr        EQU     $00FFFFFF

*-----------------------------------------------------------
* START
*-----------------------------------------------------------
start:
    JSR     welcome                 * welcome, ask for start/end
    JSR     clear_all_reg
    JSR     read
    
    
    MOVE.B  #9,D0
    TRAP    #15                     * haltsim
    
   
*-----------------------------------------------------------
* INPUT
*-----------------------------------------------------------

*-----------------------------------------------------------
* Subroutines:
* -welcome
* -get_start_addr: gets the starting address
* -get_end_addr: gets the ending address
* -get_addr: prompts user for address, makes sure it is valid
* -get_addr_loop: loops to translate entire addr
* -asciiToHex: converts ascii to hex. Requires:
*    >convert_no: converts number
*    >convert_uc_char: converts upper case character
*    >convert_lc_char: converts lower case character
*-----------------------------------------------------------
welcome
    JSR     clear_all_reg
    LEA     welcomeMSG,A1           * load welcome message
    MOVE.B  #14,D0
    TRAP    #15                     * display welcome message
    JSR     get_start_addr
    JSR     get_end_addr
    RTS

get_start_addr
    LEA     startMSG,A1
    MOVE.L  #min_addr,D4
    MOVE.B  #14,D0
    TRAP    #15                     * ask for starting address
    JSR     get_addr
    MOVE.L  #0,A6
    MOVEA.L #start_addr,A6
    MOVE.L  D6,0(A6)                 * copy converted addr to start_addr
    
    MOVE.L  D6,D4                   * min address now start_addr
    RTS
    
get_end_addr    
    LEA     endMSG,A1
    MOVE.B  #14,D0
    TRAP    #15                     * ask for ending address
    JSR     get_addr
    MOVE.L  #0,A6
    MOVEA.L #end_addr,A6
    MOVE.L  D6,0(A6)                 * copy converted addr to start_addr
    RTS
    
get_addr
   CLR      D1                      * clear length, conversion, flag, previous input
   CLR      D2
   CLR      D3
   CLR      D6                       
   LEA      user_input,A1
   MOVE.B   #2,D0
   TRAP     #15                     * get user input
   JSR      check_input_length  
   CMP.B    #1,D3             
   BEQ      get_addr                 * if invalid input flag is set, ask again
  
get_addr_loop                   
    MOVE.B  (A1)+,D2
    ASL.L   #4,D6
    JSR     ascii_to_hex
    CMP.B   #1,D3                   * if invalid input flag is set, ask again
    BEQ     get_addr
    ADD.B   D2,D6
    SUBI.B  #1,D1
    BNE     getAddrLoop             * keep looping until reach end of length   
    CMP.B   #1,D3                   
    BEQ     get_addr                * if invalid input flag is set, ask again
    JSR     check_input_range
    CMP.B   #1,D3     
    BEQ     get_addr                * if invalid input flag is set, ask again
    RTS
    
check_input_length
    CMPI.W  #8,D1
    BGT     invalid_addr            * error if input longer than 8
    RTS
    
check_input_range
    CMP.L   D4,D6                   * check if input below min
    BLT     invalid_addr
    CMP.L   #max_addr,D6            * check if input above max
    BGT     invalid_addr
    RTS
    
ascii_to_hex
    CMPI.B  #$30,D2
    BLT     invalid_addr             * if input lower than number, invalid
    CMPI.B  #$3A,D2
    BLT     convert_no               * if input is number, then subtract 30 to convert
    CMPI.B  #$41,D2                 
    BLT     invalid_addr             * if input between numbers and letters, invalid
    CMPI.B  #$47,D2
    BLT     convert_uc_char           * if input is UC letter, then subtract 37 to convert
    CMPI.B  #$61,D2
    BLT     invalid_addr             * if input between UC and LC letters, invalid
    CMPI.B  #$67,D2
    BLT     convert_lc_char           * if input is LC letter, then subtract 57 to convert
    BRA     invalid_addr      

convert_no
    SUB.B   #$30,D2
    BRA     finish_ascii_to_hex
    
convert_uc_char
    SUB.B   #$37,D2
    BRA     finish_ascii_to_hex
 
convert_lc_char
    SUB.B   #$57,D2
    BRA     finish_ascii_to_hex
         
invalid_addr
    LEA     AddrErrMSG,A1           * load error message
    MOVE.B  #14,D0
    TRAP    #15         
    MOVE.B  #1,D3                   * set invalid flag to true
    
finish_ascii_to_hex
    RTS 
    
*-----------------------------------------------------------
* READING
*-----------------------------------------------------------

*-----------------------------------------------------------
* Subroutines:
* -read_next_word: puts read word into currWord, increments currAddr
*-----------------------------------------------------------
read
    MOVEA.L #currAddr,A1
    MOVEA.L #start_addr,A3
    MOVE.L  (A3),D3
    MOVE.L  D3,0(A1)              * set currAddr to start_addr
    JSR     clear_all_reg

read_loop
    MOVEA.L #currAddr,A1
    MOVE.L  0(A1),D1
    MOVEA.L #end_addr,A3
    MOVE.L  0(A3),D3
    CMP.L   D3,D1
    BGE     finish_read              * finish reading when currAddr >= end_addr
    JSR     read_next_word
    JSR     code_data
    LEA     returnMSG,A1
    MOVE.B  #14,D0
    TRAP    #15                     * next line
    JSR     clear_all_reg
    BRA     read_loop

read_next_word
    MOVEA.L #currAddr,A0
    MOVE.L  (A0),D0
    MOVEA.L D0,A1
    MOVE.W  (A1)+,D1
    MOVE.L  A1,(A0)                 * copy new address to currAddr
    MOVEA.L #currWord,A2
    MOVE.W  D1,(A2)                 * store read word in currWord
    JSR     clear_all_reg
    RTS
    
finish_read
    RTS

*-----------------------------------------------------------
* OUTPUT
*-----------------------------------------------------------
code_data
    MOVEA.L #currAddr,A1 
    CLR.L   D1
    MOVE.L  (A1),D1       
    MOVE.B  #16,D2
    MOVE.B  #15,D0                  * print address of word
    TRAP    #15
    LEA     spaceMSG,A1
    MOVE.B  #14,D0
    TRAP    #15                     * print a space
    LEA     DATAMSG,A1
    TRAP    #15                     * print DATA
    LEA     spaceMSG,A1
    TRAP    #15                     * print a space
    MOVEA.L #currWord,A1 
    CLR.L   D1
    MOVE.W  (A1),D1
    MOVE.B  #15,D0                  
    TRAP    #15                     * print word
    RTS          
    
instruction_print
    *print buffer
    * increase returns by 1
    * compare with 30
    * if returns is 30, force user to press enter, set returns to 0
    * if returns is 

*-----------------------------------------------------------
* GENERAL SUBROUTINES
*-----------------------------------------------------------
 
*-----------------------------------------------------------
* CLEARING
* -clear_all_reg: clears all registers
* -clearAddrReg: clears all address registers EXCEPT for A7
* -clearDataReg: clears all data registers
*-----------------------------------------------------------
clear_all_reg
    JSR     clear_addr_reg
    JSR     clear_data_reg
    RTS

clear_addr_reg
    MOVE.L  #0,A0
    MOVE.L  #0,A1
    MOVE.L  #0,A2
    MOVE.L  #0,A3
    MOVE.L  #0,A4
    MOVE.L  #0,A5
    MOVE.L  #0,A6
    RTS
    
clear_data_reg
    CLR.L   D0
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D4
    CLR.L   D5
    CLR.L   D6
    CLR.L   D7
    RTS
    
    SIMHALT             ; halt simulator

* Put variables and constants here
*-----------------------------------------------------------
* STORAGE VARIABLES
*-----------------------------------------------------------
currWord   DS.W     1        * pointer to current word
currAddr   DS.L     1        * address of current pointer
start_addr DS.L     1
end_addr   DS.L     1

*-----------------------------------------------------------
* VARIABLES FOR PRINTING
*-----------------------------------------------------------

*-----------------------------------------------------------
* MESSAGES FOR USER
*-----------------------------------------------------------
welcomeMSG  DC.B    'Welcome to the Motorola 68000 disassembler!',CR,LF,0
startMSG    DC.B    'Please enter in a starting address from $6000 to $00FFFFFF: ',CR,LF,0
endMSG      DC.B    'Please enter in an end location up to $00FFFFFF: ',CR,LF,0
addrErrMSG  DC.B    'That is not a valid address. Please enter a valid address',CR,LF,0


*-----------------------------------------------------------
* OPERATIONS
*-----------------------------------------------------------
NOPMSG      DC.B    'NOP',0
MOVEMSG     DC.B    'MOVE',0
MOVEAMSG    DC.B    'MOVEA',0
MOVEQMSG    DC.B    'MOVEQ',0
MOVEMMSG    DC.B    'MOVEM',0
ADDMSG      DC.B    'ADD',0
ADDAMSG     DC.B    'ADDA',0
ADDIMSG     DC.B    'ADDI',0
ADDQMSG     DC.B    'ADDQ',0
ANDMSG      DC.B    'AND',0
ASLMSG      DC.B    'ASL',0
ASRMSG      DC.B    'ASR',0
MULSMSG     DC.B    'MULS',0
DIVUMSG     DC.B    'DIVU',0
LEAMSG      DC.B    'LEA',0
CLRMSG      DC.B    'CLR',0
ORMSG       DC.B    'OR',0
LSLMSG      DC.B    'LSL',0
LSRMSG      DC.B    'LSR',0
ROLMSG      DC.B    'ROL',0
RORMSG      DC.B    'ROR',0
CMPMSG      DC.B    'CMP',0
BCCMSG      DC.B    'BCC',0
BGTMSG      DC.B    'BGT',0
BLEMSG      DC.B    'BLE',0
JSRMSG      DC.B    'JSR',0
RTSMSG      DC.B    'RTS',0
DATAMSG     DC.B    'DATA',0

*-----------------------------------------------------------
* SIZES
*-----------------------------------------------------------
byteMSG     DC.B    '.B',0
wordMSG     DC.B    '.W',0
longMSG     DC.B    '.L',0

*-----------------------------------------------------------
* DATATYPES
*-----------------------------------------------------------
binMSG      DC.B    '%',0
hexMSG      DC.B    '$',0
immMSG      DC.B    '#',0

*-----------------------------------------------------------
* OTHER SYMBOLS
*-----------------------------------------------------------
spaceMSG    DC.B    ' ',0
plusMSG     DC.B    '+',0
minusMSG    DC.B    '-',0
lParenMSG   DC.B    '(',0
rParenMSG   DC.B    ')',0
commaMSG    DC.B    ',',0
periodMSG   DC.B    '.',0
returnMSG   DC.B    '',CR,LF,0


    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
