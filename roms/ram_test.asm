; ram_test.asm
; test the Intel 4002
init    NOP
        LDM 4
        XCH R4         ; initialize R4=3
        LDM 1
        XCH R5         ; initialize R5=1

loop0   FIM R0R1, 0    ; initialize R0=R1=0
        FIM R2R3, 0    ; initialize R2=R3=0
        LDM 12         ; load 12 to accumulator
        XCH R2         ; initialize R2=12
        XCH R4         ; load bank number to accumulator
        SUB R5         ; decrement bank number
        DCL            ; select bank number
        XCH R4         ; store bank number to R4

loop1   SRC R0R1       ; select register & address
        WRM            ; write accumulator to memory
        IAC            ; increment accumulator
        ISZ R1, loop1  ; loop 16 times
        INC R0         ; increment R0
        ISZ R2, loop1  ; loop 4 times

        FIM R0R1, 0    ; initialize R0=R1=0
        FIM R2R3, 0    ; initialize R2=R3=0
        LDM 12         ; load 12 to accumulator
        XCH R2         ; initialize R2=12

loop2   SRC R0R1       ; select register & address
        WR0            ; write status character 0
        IAC            ; increment accumulator
        WR1            ; write status character 1
        IAC            ; increment accumulator
        WR2            ; write status character 2
        IAC            ; increment accumulator
        WR3            ; write status character 3
        IAC            ; increment accumulator
        INC R0         ; increment R0
        ISZ R2, loop2  ; loop 4 times

        LD  R4
        JCN CNZ, loop0 ; loop 4 times over banks

; End state, write to sentinel to output ports
done    LDM $6
        WMP
        LDM $F
        WRR

CNZ=3