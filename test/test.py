# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.types.logic import Logic

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.bus.value = Logic("Z")
    dut.load.value = 0
    dut.enable_output.value = 0
    await ClockCycles(dut.clk, 10)
    dut.load.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.bus.value = 128

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.regA.value == 128

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
