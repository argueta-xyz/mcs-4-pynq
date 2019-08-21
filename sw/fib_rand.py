#!/usr/bin/env python
import argparse

def getFibRand(i, prev):
  f = prev + prev2

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('x')
  args = parser.parse_args()
  fibs = [0, 1, 1]
  x = int(args.x)
  if x < 3:
    f = fibs[x]
  else:
    for i in range(x-2):
      fibs[0] = fibs[1]
      fibs[1] = fibs[2]
      fibs[2] = fibs[1] + fibs[0]
      fibs[2] = 0x7F & fibs[2]
    f = fibs[2]
  print(f)


if __name__ == '__main__':
    # execute only if run as a script
    main()