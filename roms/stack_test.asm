; Load hardcoded addr of main and jump indirect
init    NOP
        LDM $6
        XCH R0
        JIN P0
        NOP
        NOP

; Load 1 and write to Reg0
main    LD  $1
        XCH R0

 ; Jump to incr subroutine, then loop back
loop    JMS incr
        JUN loop

; Increment Reg0, return 2
incr    INC R0
        BBL $2