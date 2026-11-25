# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer, RisingEdge, FallingEdge

async def apply_operation(dut, a, b, opcode):
    await RisingEdge(dut.clk)
    
    dut.ui_in.value = ((a & 0xF) << 4) | (b & 0xF)
    dut.uio_in.value = opcode & 0xF

    await RisingEdge(dut.clk)

    await Timer(1, unit="ns")

    # Diagnosis because I'm not too sure what I'm doing wrong
    # in my github actions
    dut._log.info(f"ui_in = {dut.ui_in.value}")
    dut._log.info(f"uio_in = {dut.uio_in.value}")
    dut._log.info(f"clk = {dut.clk.value}")
    dut._log.info(f"rst_n = {dut.rst_n.value}")
    dut._log.info(f"uo_out = {dut.uo_out.value}")

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

    await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    dut._log.info("Reset complete")

    dut._log.info("Test project behavior")

    result = await apply_operation(dut, 5, 3, 0)
    dut._log.info(f"Add: 5 + 3 {result}")
    assert result == 8

    result = await apply_operation(dut, 5, 3, 2)
    dut._log.info(f"Mult: 5 * 3 = {result}")
    assert result == 15

    result = await apply_operation(dut, 13, 3, 3)
    dut._log.info(f"Div: 13 / 3 = {hex(result)}")
    assert result == 0x14

    result = await apply_operation(dut, 9, 0, 15)
    dut._log.info(f"Rotate: 9 -> {hex(result)}")
    assert result == 0x30

    dut._log.info("ALU basic tests passed!")