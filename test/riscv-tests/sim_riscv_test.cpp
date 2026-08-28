#include <Vchrysoberyl_Chrysoberyl.h>
#include <verilated.h>

#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

namespace {
constexpr std::size_t kRomBytes = 1u << 14;
constexpr std::size_t kRamBytes = 1u << 10;
constexpr std::size_t kDataBase = 0x10000;
constexpr int kMaxCycles = 20000;

std::array<std::uint32_t, kRomBytes / 4> rom{};
std::array<std::uint32_t, kRamBytes / 4> ram{};

void set_byte(std::uint32_t& word, std::size_t address, unsigned char value) {
    const auto shift = 8 * (address & 3);
    const std::uint32_t mask = 0xffu << shift;
    word = (word & ~mask) | (std::uint32_t(value) << shift);
}

bool load_image(const std::string& path) {
    std::ifstream stream(path, std::ios::binary);
    if (!stream) {
        std::cerr << "unable to open image: " << path << '\n';
        return false;
    }
    const std::vector<unsigned char> image{
        std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>()};
    for (std::size_t address = 0; address < image.size(); ++address) {
        if (address < kRomBytes) {
            set_byte(rom[address / 4], address, image[address]);
            // The core has Harvard ports, but architectural loads may address
            // constants in the low text region. Mirror the overlapping range
            // into writable data memory, as a unified external map would.
            if (address < kRamBytes) {
                set_byte(ram[address / 4], address, image[address]);
            }
        } else if (address >= kDataBase && address < kDataBase + kRamBytes) {
            const auto offset = address - kDataBase;
            set_byte(ram[offset / 4], offset, image[address]);
        } else if (image[address] != 0) {
            std::cerr << "nonzero image byte outside core memory at 0x" << std::hex
                      << address << std::dec << '\n';
            return false;
        }
    }
    return true;
}

void drive_memory(Vchrysoberyl_Chrysoberyl& dut) {
    dut.i_rom_data = rom[dut.o_rom_addr % rom.size()];
    const auto ram_word = (dut.o_ram_addr >> 2) % ram.size();
    dut.i_ram_read_data = ram[ram_word];
}

void cycle(Vchrysoberyl_Chrysoberyl& dut) {
    dut.i_clk = 0;
    drive_memory(dut);
    dut.eval();

    const auto address = dut.o_ram_addr;
    const auto data = dut.o_ram_write_data;
    const auto enables = dut.o_ram_we;

    dut.i_clk = 1;
    drive_memory(dut);
    dut.eval();

    auto& word = ram[(address >> 2) % ram.size()];
    for (unsigned byte = 0; byte < 4; ++byte) {
        if (enables & (1u << byte)) {
            const std::uint32_t mask = 0xffu << (8 * byte);
            word = (word & ~mask) | (data & mask);
        }
    }
}
}  // namespace

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: " << argv[0] << " <flat-binary-image>\n";
        return 2;
    }
    if (!load_image(argv[1])) return 2;

    Verilated::commandArgs(argc, argv);
    Vchrysoberyl_Chrysoberyl dut;
    dut.i_rst = 0;
    cycle(dut);
    dut.i_rst = 1;

    for (int count = 0; count < kMaxCycles; ++count) {
        cycle(dut);
        const auto tohost = ram[0];
        if (tohost == 1) return 0;
        if (tohost != 0) {
            std::cerr << "failed test " << (tohost >> 1) << " (tohost=0x"
                      << std::hex << tohost << std::dec << ")\n";
            return 1;
        }
    }

    std::cerr << "timeout after " << kMaxCycles << " cycles\n";
    return 1;
}
