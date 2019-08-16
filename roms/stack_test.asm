; Load 1 and write to Reg0
init
  NOP
  LD  $1
  XCH $0

 ; Jump to incr subroutine, then loop back
loop
  JMS incr
  JUN loop

; Increment Reg0, return 2
incr
  INC $0
  BBL $2