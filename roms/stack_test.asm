init
  NOP
  LD  $1
  XCH $0

loop
  JMS incr
  JUN loop

incr
  INC $0
  BBL $2