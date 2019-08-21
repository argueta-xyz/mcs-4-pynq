rdarg	LDM 0
		XCH R0
		XCH R1		; R0R1 = 0
		SRC R0R1
		RDR
		XCH R4		; Read ROM port 0x0 to R4, R5 is 0x0, so arg = 2*(ROM Input)

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

ckarg0	LD	R4
		JCN CNZ	ckarg1
		LD	R5
		JCN CNZ	ckarg1
		JUN done		; arg == 0? Done if so

ckarg1	LDM 1
		SUB	R4
		JCN CNZ	ckarg2
		CLB
		LD	R5
		LDM 1
		XCH R0
		JCN CZ	done	; arg == 1? done if so

ckarg2	LDM 2
		SUB	R4
		JCN CNZ	fibmn
		CLB
		LD	R5
		LDM 1
		XCH R0
		JCN CZ	done	; arg == 2? done if so

		LD	R5
		XCH	R7
		LD	R4
		XCH	R6	; Copy arg to R6R7

decr	CLC
		LDM 1
		LD	R7
fibmn	NOP

done	NOP

CZ=%0010
CNZ=%0011