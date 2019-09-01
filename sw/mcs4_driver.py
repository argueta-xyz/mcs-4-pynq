from pynq import DefaultIP

class Mcs4Driver(DefaultIP):
    def __init__(self, description):
        super().__init__(description=description)

    bindto = ['argueta.xyz:user:mcs4:1.0']

    RAM_TEST = [0xD1B4D400, 0x220020B5, 0xB4B2DC00, 0x21B4FD95,
                0x0F71F2E0, 0x200F7260, 0xDC002200, 0xF2E421B2,
                0xF2E6F2E5, 0x7260F2E7, 0x0513A41D, 0xE2DFE1D6]

    FIB_RAND = [0x21002000, 0x1020B5EA, 0x20B4EA21, 0xE0D02100,
                0xD121B1D2, 0x21B1D4E0, 0x13A5E0D1, 0x2213A422,
                0x95D1B940, 0xD1F02C13, 0xB912A4B1, 0x361394D2,
                0xB0D1A5F0, 0x7650B912, 0x13A44040, 0xB912A540,
                0x02207650, 0xB7A38950, 0x0020B6A2, 0x04209250,
                0xB9A38950, 0x0220B8A2, 0x9B509250, 0xB2A6B3A7,
                0xB6DFB7A3, 0xB3A9A450, 0xB6D7B7A2, 0xB2A9A450,
                0x92500420, 0xD1F13A40, 0xD0B595B5, 0xB494B4F5,
                0xF2B1F0C0, 0xB080F5B1, 0xB3E921C0, 0xE9218150,
                0xA321C0B2, 0x218150E0, 0xF0C0E0A2, 0xF5B789B7,
                0xC0B68886, 0xB8D4B9F0, 0x15B6F6A6, 0xF6A7F1B1,
                0xB9F6A9B7, 0xA713F8A8, 0x230022C0, 0xBE40E1D6]


    CTL_BASE_ADDR = 0x0000
    ROM_BASE_ADDR = 0x1000
    RAM_BASE_ADDR = 0x2000
    IO_BASE_ADDR  = 0x3000

    def reset(self):
        self.write(0x0, 0x7)
        self.write(0x0, 0x0)
        return self.read(0x0)

    def read_block(self, addr, size):
        contents = []
        for i in range(0, size):
            contents.append(self.read(addr + i * 4))
        return contents

    def write_block(self, addr, word_array):
        i = 0x0
        for word in word_array:
            self.write(addr + i, word)
            i += 0x4

    def init_rom(self, word_array):
        self.write_block(self.ROM_BASE_ADDR, word_array)

    def read_rom(self, addr, size):
        return self.read_block(self.ROM_BASE_ADDR + addr, size)

    def set_inputs(self, hi, lo):
        self.write(self.CTL_BASE_ADDR + 0x10, 0x1);
        self.write(self.IO_BASE_ADDR  + 0x0, lo);
        self.write(self.IO_BASE_ADDR  + 0x4, hi);

    def read_ram(self, addr, size):
        return self.read_block(self.RAM_BASE_ADDR + addr, size)

    def zero_ram(self):
        for i in xrange(0, 128):
            self.write(self.RAM_BASE_ADDR + i * 4, 0x0)