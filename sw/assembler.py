#!/usr/bin/env python
from __future__ import print_function
import argparse

class Instruction:
  label = ''
  opr = ''
  opa = ''
  isDouble = False
  byte2 = ''
  tokens = []
  hexRep = []

  def __str__(self):
    return '%s\t[%s.%s%s]\t-> %s' % (
              '%s:' % self.label if self.label else '',
              self.opr,
              self.opa,
              '.%s' % (self.byte2) if self.isDouble else '',
              self.tokens)


def stripComments(line):
  code = line.split(';')[0]
  sansCommas = code.split(',')
  lineTokens = []
  for tokens in sansCommas:
    lineTokens += tokens.split()
  return lineTokens

GLOBALS = {
  'labels' : {},
  'defines' : {}
}

OPR_CODES = {
  'NOP' : 0x0,
  'JCN' : 0x1,
  'FIM' : 0x2,
  'SRC' : 0x2,
  'FIN' : 0x3,
  'JIN' : 0x3,
  'JUN' : 0x4,
  'JMS' : 0x5,
  'INC' : 0x6,
  'ISZ' : 0x7,
  'ADD' : 0x8,
  'SUB' : 0x9,
  'LD'  : 0xA,
  'XCH' : 0xB,
  'BBL' : 0xC,
  'LDM' : 0xD,
  'WRM' : 0xE,
  'WMP' : 0xE,
  'WRR' : 0xE,
  'WR0' : 0xE,
  'WR1' : 0xE,
  'WR2' : 0xE,
  'WR3' : 0xE,
  'SBM' : 0xE,
  'RDM' : 0xE,
  'RDR' : 0xE,
  'ADM' : 0xE,
  'RD0' : 0xE,
  'RD1' : 0xE,
  'RD2' : 0xE,
  'RD3' : 0xE,
  'CLB' : 0xF,
  'CLC' : 0xF,
  'IAC' : 0xF,
  'CMC' : 0xF,
  'CMA' : 0xF,
  'RAL' : 0xF,
  'RAR' : 0xF,
  'TCC' : 0xF,
  'DAC' : 0xF,
  'TCS' : 0xF,
  'STC' : 0xF,
  'DAA' : 0xF,
  'KBP' : 0xF,
  'DCL' : 0xF
}

OPA_CODES = {
  'NOP' : 0x0,
  'WRM' : 0x0,
  'WMP' : 0x1,
  'WRR' : 0x2,
  'WR0' : 0x4,
  'WR1' : 0x5,
  'WR2' : 0x6,
  'WR3' : 0x7,
  'SBM' : 0x8,
  'RDM' : 0x9,
  'RDR' : 0xA,
  'ADM' : 0xB,
  'RD0' : 0xC,
  'RD1' : 0xD,
  'RD2' : 0xE,
  'RD3' : 0xF,
  'CLB' : 0x0,
  'CLC' : 0x1,
  'IAC' : 0x2,
  'CMC' : 0x3,
  'CMA' : 0x4,
  'RAL' : 0x5,
  'RAR' : 0x6,
  'TCC' : 0x7,
  'DAC' : 0x8,
  'TCS' : 0x9,
  'STC' : 0xA,
  'DAA' : 0xB,
  'KBP' : 0xC,
  'DCL' : 0xD
}

TWO_BYTE_OPS = {
  'JCN' : 'ADDR',
  'FIM' : 'DATA',
  'JUN' : 'ADDR',
  'JMS' : 'ADDR',
  'ISZ' : 'ADDR'
}

MODIFIER_TYPES = {
  'JCN' : 'COND',
  'FIM' : 'REGP',
  'SRC' : 'REGP',
  'FIN' : 'REGP',
  'JIN' : 'REGP',
  'JUN' : 'ADDR',
  'JMS' : 'ADDR',
  'INC' : 'REG',
  'ISZ' : 'REG',
  'ADD' : 'REG',
  'SUB' : 'REG',
  'LD'  : 'REG',
  'XCH' : 'REG',
  'BBL' : 'DATA',
  'LDM' : 'DATA'
}


REG_CODES = {
  'R0' : 0x0,
  'R1' : 0x1,
  'R2' : 0x2,
  'R3' : 0x3,
  'R4' : 0x4,
  'R5' : 0x5,
  'R6' : 0x6,
  'R7' : 0x7,
  'R8' : 0x8,
  'R9' : 0x9,
  'R10' : 0xA, 'RA' : 0xA,
  'R11' : 0xB, 'RB' : 0xB,
  'R12' : 0xC, 'RC' : 0xC,
  'R13' : 0xD, 'RD' : 0xD,
  'R14' : 0xE, 'RE' : 0xE,
  'R15' : 0xF, 'RF' : 0xF
}

REGP_CODES = {
  'P0' : 0x0, 'R0R1' : 0x0,
  'P1' : 0x1, 'R2R3' : 0x1,
  'P2' : 0x2, 'R4R5' : 0x2,
  'P3' : 0x3, 'R6R7' : 0x3,
  'P4' : 0x4, 'R8R9' : 0x4,
  'P5' : 0x5, 'RARB' : 0x5, 'R10R11' : 0x5,
  'P6' : 0x6, 'RCRD' : 0x6, 'R12R13' : 0x6,
  'P7' : 0x7, 'RERF' : 0x7, 'R14R15' : 0x7
}

def parseNum(num):
  if num.startswith('$'):
    return int(num[1:], 16)
  elif num.startswith('%'):
    return int(num[1:], 2)
  elif num.startswith('0'):
    return int(num, 8)
  else:
    return int(num)

def getHexRep(instr):
  # OPR
  i = 0
  hexRep = [OPR_CODES[instr.opr]]
  i += 1
  # OPA
  if instr.opa == 'COND':
    hexRep.append(GLOBALS['defines'][instr.tokens[1]])
  elif instr.opa == 'REGP':
    regp = REGP_CODES[instr.tokens[1]] << 1
    if instr.opr == 'JIN' or instr.opr == 'SRC':
      regp |= 0x1
    hexRep.append(regp)
  elif instr.opa == 'REG':
    hexRep.append(REG_CODES[instr.tokens[1]])
  elif instr.opa == 'ADDR':
    # ADDR HI, append all
    pass
    # hexRep.append(GLOBALS['labels'][instr.tokens[i]])
  elif instr.opa == 'DATA':
    hexRep.append(parseNum(instr.tokens[1]))
  else:
    hexRep.append(instr.opa)
  i += 1
  if instr.isDouble:
    if instr.byte2 == 'ADDR':
      if instr.opa == 'ADDR':
        addr = GLOBALS['labels'][instr.tokens[1]]
        hexRep += [addr >> 8 & 0xF, addr >> 4 & 0xF, addr & 0xF]
      else:
        addr = GLOBALS['labels'][instr.tokens[2]]
        hexRep += [addr >> 4 & 0xF, addr & 0xF]
    elif instr.byte2 == 'DATA':
      data = parseNum(instr.tokens[2])
      hexRep += [data >> 4 & 0xF, data & 0xF]
  return hexRep

def parseLine(line, addr):
  encoded = []
  instr = Instruction()
  # parse comments
  i = 0
  if(not line[i] in OPR_CODES):
    if('=' in line[i]):
      # Is define
      define = [d.strip() for d in line[i].split('=')]
      GLOBALS['defines'][define[0]] = int(define[1])
      return None
    # Is label
    instr.label = line[0]
    GLOBALS['labels'][line[0]] = addr
    i += 1
  # Is OPR
  if line[i] not in OPR_CODES:
    print('ERROR: Invalid OPR code: %s', line[i])
    return
  instr.opr = line[i]
  # Parse OPA
  if instr.opr in MODIFIER_TYPES:
    instr.opa = MODIFIER_TYPES[instr.opr]
  elif instr.opr in OPA_CODES:
    instr.opa = OPA_CODES[instr.opr]
  else:
    print('ERROR: No OPA code for OPR: %s', instr.opr)

  # Parse double
  if instr.opr in TWO_BYTE_OPS:
    instr.isDouble = True
    instr.byte2 = TWO_BYTE_OPS[instr.opr]

  instr.tokens = line[i:]
  return instr

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('asm')
  args = parser.parse_args()
  codeTokens = []
  with open(args.asm) as f:
    lines = f.readlines()
    for line in lines:
      stripped = stripComments(line)
      if stripped:
        codeTokens.append(stripped)

  # Parse Instruction types
  instrs = []
  addr = 0
  for line in codeTokens:
    instr = parseLine(line, addr)
    if instr:
      instrs.append(instr)
      addr += 2 if instr.isDouble else 1

  # Convert to Binary
  hexRom = []
  for instr in instrs:
    hexRep = getHexRep(instr)
    hexRom += hexRep
    print('%s = %s' % (instr, hexRep))

  i = 0
  print('\nROM Hex:\n===========================')
  hexRomOut = ''
  for nibble in hexRom:
    if i % 16 == 0 and i != 0:
      hexRomOut += '\n'
    elif i % 2 == 0 and i != 0:
      hexRomOut += ' '
    i += 1
    hexRomOut += format(nibble, 'X')
  print(hexRomOut)
  print('===========================')
  hromFilename = args.asm[:-3] + 'hrom'
  with open(hromFilename, 'w') as f:
    f.write(hexRomOut)
    f.write('\n')


if __name__ == '__main__':
    # execute only if run as a script
    main()