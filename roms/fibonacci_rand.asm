		NOP
rdarg	FIM R0R1, $00
		SRC R0R1
		RDR
		XCH R5		; Read ROM port [1, 0] -> [R4, R5]
		FIM R0R1, $10
		SRC R0R1
		RDR
		XCH R4

setup	LDM 0
		SRC R0R1
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
		JCN CNZ	cparg
		CLB
		LD	R5
		LDM 1
		XCH R0
		JCN CZ	done	; arg == 2? done if so

cparg	LD	R5
		XCH	R7
		LD	R4
		XCH	R6	; Copy arg to R6R7
		JMS decarg
		JMS decarg
		JUN fibmn

decarg	CLC
		LDM 1
		XCH R7	; {c,accum} = {0,arg.lo}, R6 = 1
		SUB R7	; {c,accum} = {b,arg.lo - 1}
		XCH R7	; {c,accum} = {b,1},      R6 = arg.lo - 1
		LDM 0	; {c,accum} = {b,0}
		RAL		; {c,accum} = {0,b}
		XCH R6  ; accum = arg.hi, R7 = b
		SUB R6
		XCH R6  ; accum = b,      R7 = arg.hi - b
		BBL 0


fibmn	NOP

done	FIM R2R3, $00
		SRC R2R3
		LDM $6 ; Write to RAM output port
		WMP

CZ=%0010
CNZ=%0011