# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, RisingEdge


async def apply_operation(dut, a, b, opcode):
    dut.ui_in.value = (a << 4) | b
    dut.uio_in.value = opcode

    await RisingEdge(dut.clk)

    await Timer(1, unit="ns")

    return int(dut.uo_out.value)

@cocotb.test()
async def test_arc_angel_alu(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    # dut.ui_in.value = 20
    # dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.

    assert await apply_operation(dut, 5, 3, 0) == 8

    assert await apply_operation(dut, 5, 3, 2) == 15

    assert await apply_operation(dut, 13, 3, 3) == 0x14

    assert await apply_operation(dut, 9, 0, 15) == 0x30

    dut._log.info("ALU basic tests passed!")