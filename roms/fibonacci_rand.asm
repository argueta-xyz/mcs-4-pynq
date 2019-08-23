		NOP
rdarg	FIM R0R1, $00
		SRC R0R1
		RDR
		XCH R5
		FIM R0R1, $10
		SRC R0R1
		RDR
		XCH R4		; Read ROM port [1, 0] -> [R4, R5]

setup	FIM R0R1, $00
		SRC R0R1
		LDM 0
		WRM
		LDM 2
		XCH R1
		SRC R0R1
		LDM 1
		WRM
		LDM 4
		XCH R1
		SRC R0R1
		LDM 1
		WRM			; RAM[5:0] = [0x01, 0x01, 0x0]

ckarg0	LD	R5
		JCN CNZ	ckarg1
		LD	R4
		JCN CNZ	ckarg1
		JUN done		; arg == 0? Done if so

ckarg1	LDM 1
		SUB	R5
		JCN CNZ	ckarg2
		CLB
		LDM 1
		XCH R1			; preload answer in case arg == 1
		LD	R4
		JCN CZ	done	; arg == 1? done if so

ckarg2	LDM 2
		SUB	R4
		JCN CNZ	prparg
		CLB
		LD	R5
		LDM 1
		XCH R0
		JCN CZ	done	; arg == 2? done if so

prparg	JMS decarg
		JMS decarg
		JUN fibmn

decarg	CLC
		LDM 1
		XCH R5		; {c,accum} = {0,arg.lo}, R5 = 1
		SUB R5		; {c,accum} = {b,arg.lo - 1}
		XCH R5		; {c,accum} = {b,1},      R5 = arg.lo - 1
		LDM 0		; {c,accum} = {b,0}
		RAL			; {c,accum} = {0,b}
		XCH R4  	; accum = arg.hi, R4 = b
		SUB R4
		XCH R4  	; accum = b,      R4 = arg.hi - b
		BBL 0

ckdone	LD R4
		JCN CNZ fibmn
		LD R5
		JCN CZ	done

; fib[2:0] stored in mem[5:0]
;
fibmn	FIM R0R1 2
		JMS	ld8		; R2R3 = fib[1]
		LD	R3
		XCH R7
		LD	R2
		XCH R6		; R6R7 = fib[1]
		FIM R0R1 0
		JMS wr8		; fib[0] = fib[1]

		FIM R0R1 4
		JMS	ld8
		LD	R3
		XCH R9
		LD	R2
		XCH R8		; R8R9 = fib[2]
		FIM R0R1 2
		JMS wr8		; fib[1] = fib[2]

		JMS add8
		LD	R7
		XCH R3
		LD	R6
		XCH	R2		; R2R3 = (new)fib[0] + (new)fib[1]

		FIM	R0R1 4
		JMS wr8		; fib[2] = (new)fib[0] + (new)fib[1]
		; TODO: Implement 0x7F & fib[2]
		JUN	ckdone


; Subroutines
; NextAddr: Increments 8bit addr
; Args:		R0R1 = addr1
; Returns:	R0R1 = addr2
nxtadr	LD	R1	 	; addr1 = R0R1
		CLC		 	; {c,accum} = {0,addr1.lo}
		IAC		 	; {c,accum} = {c,addr2.lo}
		XCH R1	 	; {c,accum} = {c,?}, R1 = addr2.lo
		LDM 0	 	; {c,accum} = {c,0}
		RAL		 	; {c,accum} = {0,c}
		ADD R0	 	; {c,accum} = {c,addr2.hi}
		XCH R0	 	; R0R1 = addr2
		BBL 0

; LoadByte:	Loads 8-bits from memory
; Args:		R0R1 = raddr
; Returns:	R2R3 = rdata
ld8		SRC R0R1
		RDM
		XCH R3
		JMS nxtadr
		SRC R0R1
		RDM
		XCH	R2
		BBL 0

; WriteByte: Writes 8-bits to memory
; Args:		R0R1 = waddr, R2R3 = wdata
; Returns:	N/A
wr8		SRC R0R1
		LD R3
		WRM
		JMS nxtadr
		SRC R0R1
		LD R2
		WRM
		BBL 0

; AddBytes: Adds 2 bytes together
; Args:		R6R7 = a, R8R9 = b
; Returns:	R6R7 = a + b
add8	CLC
		LD	R7
		ADD	R9
		XCH R7
		LDM 0
		RAL
		ADD R6
		ADD R8
		XCH R6
		BBL 0


done	FIM R2R3, $00
		SRC R2R3
		LDM $6 		; Write to RAM output port
		WMP

CZ=%0010
CNZ=%0011