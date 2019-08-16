; Load Immediates into ACCUM and Exchange into regs
NOP
LDM $F
XCH $0
LDM $E
XCH $1
LDM $D
XCH $2
LDM $C
XCH $3
LDM $B
XCH $4
LDM $A
XCH $5
LDM $9
XCH $6
LDM $8
XCH $7
LDM $7
XCH $8
LDM $6
XCH $9
LDM $5
XCH $A
LDM $4
XCH $B
LDM $3
XCH $C
LDM $2
XCH $D
LDM $1
XCH $E
LDM $0
XCH $F
NOP
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
XCH $0
SRC $0
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
