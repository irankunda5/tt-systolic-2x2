# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

WRITE, START, READ = 0b01, 0b10, 0b11


async def send(dut, cmd, data=0):
    """Act like the outside controller: fill in the form, then press submit (strobe)."""
    dut.ui_in.value = data & 0xFF          # & 0xFF turns -5 into its byte 251
    dut.uio_in.value = cmd                 # strobe (bit 2) low
    await ClockCycles(dut.clk, 2)
    dut.uio_in.value = cmd | 0b100         # strobe high
    await ClockCycles(dut.clk, 4)
    dut.uio_in.value = cmd                 # strobe low
    await ClockCycles(dut.clk, 4)


def to_signed24(x):
    """Read 24 bits as a signed number (two's complement, from Step 2)."""
    return x - (1 << 24) if x & (1 << 23) else x


def reference(A, B):
    """The reference model: ordinary matrix multiply."""
    return [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)]
            for i in range(2)]


async def matmul(dut, A, B):
    """Run one full transaction on the chip: write, start, wait, read."""
    for v in [A[0][0], A[0][1], A[1][0], A[1][1],
              B[0][0], B[0][1], B[1][0], B[1][1]]:
        await send(dut, WRITE, v)

    await send(dut, START)

    for _ in range(20):                    # wait for done = uio_out bit 7
        if (int(dut.uio_out.value) >> 7) & 1:
            break
        await ClockCycles(dut.clk, 1)
    else:
        assert False, "done never went high"

    r = []
    for _ in range(4):                     # 4 results...
        w = 0
        for j in range(3):                 # ...3 bytes each, lowest byte first
            w |= int(dut.uo_out.value) << (8 * j)
            await send(dut, READ)
        r.append(to_signed24(w))
    return [[r[0], r[1]], [r[2], r[3]]]


@cocotb.test()
async def test_project(dut):
    cocotb.start_soon(Clock(dut.clk, 100, "ns").start())   # 10 MHz

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    tests = [
        ([[1, 2], [3, 4]], [[5, 6], [7, 8]]),                          # Step 6 example
        ([[-128, -128], [-128, -128]], [[-128, -128], [-128, -128]]),  # worst case
        ([[127, -128], [-1, 0]], [[-128, 127], [1, -1]]),              # edge values
    ]
    random.seed(1)
    for _ in range(50):
        rnd = lambda: [[random.randint(-128, 127) for _ in range(2)] for _ in range(2)]
        tests.append((rnd(), rnd()))

    for A, B in tests:
        got = await matmul(dut, A, B)
        exp = reference(A, B)
        assert got == exp, f"A={A} B={B}: got {got}, expected {exp}"

    dut._log.info(f"PASS: {len(tests)} matrix multiplies")
