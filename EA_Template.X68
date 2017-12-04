*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
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
ea_add  RTS

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

ea_sub   RTS

ea_muls  RTS

ea_divu  RTS

ea_lea   RTS

ea_clr   RTS

ea_and   RTS

ea_or    RTS

ea_lsl   RTS

ea_lsr   RTS

ea_asr   RTS

ea_asl   RTS

ea_rol   RTS

ea_ror   RTS

ea_cmp   RTS

ea_jsr   RTS


    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
