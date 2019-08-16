; Load hardcoded addr of main and jump indirect
init    NOP
        LDM $6
        XCH R0
        JIN P0
        NOP
        NOP

; Write Reg0=1, Reg1=5
main    LDM $1
        XCH R0
        LDM $5
        XCH R1

 ; Jump to incr subroutine, and loop back if Reg0 != 5
loop    JMS incr
        LD  R0
        SUB R1
        JCN CZ tozero
        JUN loop

; Increment Reg0, return 2
incr    INC R0
        BBL $2

; Increment Reg1 until 0
tozero  ISZ R1 tozero

; End state, write to sentinel to output ports
end     LDM $6
        WMP
        LDM $F
        WRR
CZ=2