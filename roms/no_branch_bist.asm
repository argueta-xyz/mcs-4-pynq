; Load Immediates into ACCUM and Exchange into regs
NOP
LDM $F
XCH R0
LDM $E
XCH R1
LDM $D
XCH R2
LDM $C
XCH R3
LDM $B
XCH R4
LDM $A
XCH R5
LDM $9
XCH R6
LDM $8
XCH R7
LDM $7
XCH R8
LDM $6
XCH R9
LDM $5
XCH R10
LDM $4
XCH R11
LDM $3
XCH R12
LDM $2
XCH R13
LDM $1
XCH R14
LDM $0
XCH R15
NOP
; Fetch immediate to RegPair0, then FetchIndirect to RegPair7
FIM P0 $AB
FIM P0 $EF
FIN P7
FIM P7 $01
; Load RegE, add RegD, and sub RegC, then inc RegF
LD  $E
ADD $D
SUB $C
INC $F
NOP
; Increment then decrement ACCUM
IAC
IAC
IAC
IAC
IAC
IAC
DAC
DAC
DAC
; Set carry, rotate L&R, clear & set carry, clear both
STC
RAR
RAL
CLC
STC
CLB
NOP
; Complement carry & accum
CMC
CMA
CMC
CMA
NOP
; Set carry, transfer and clear both
STC
TCC
CLB
TCS
STC
TCS
CLB
NOP
; Designate command lines
DCL
IAC
DCL
RAL
DCL
RAL
DCL
CLB
DCL
; Keyboard process
KBP
KBP
; Decimal adjust
STC
DAA
; Write to memory and status reg's
CLB
XCH R0
SRC P0
WRM
WR0
WR1
WR2
WR3
; Read from memory and status reg's
CLB
RDM
CLB
RD0
CLB
RD1
CLB
RD2
CLB
RD3
; Subtract & Add from memory
LDM $1
WRM
LDM $3
SBM
WRM
ADM
; Write to RAM output port
LDM $6
WMP
; Write & Read to/from ROM I/O port
LDM $A
WRR
CLB
RDR
LDM $F
WRR
