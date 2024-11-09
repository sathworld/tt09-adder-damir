# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge
from cocotb.types.logic import Logic
from cocotb.types.logic_array import LogicArray

from random import randint, shuffle
# @cocotb.test()
# async def test_project(dut):
#     dut._log.info("Start")

#     # Set the clock period to 10 us (100 KHz)
#     clock = Clock(dut.clk, 10, units="us")
#     cocotb.start_soon(clock.start())

#     # Reset
#     dut._log.info("Reset")
#     dut.bus.value = LogicArray("ZZZZZZZZ")
#     dut.load.value = 1
#     dut.enable_output.value = 0
# 
#     dut.load.value = 0

#     dut._log.info("Test project behavior")

#     # Set the input values you want to test
#     dut.bus.value = 128

#     # Wait for two clock cycle to see the output values (one cycle fails)
#     await ClockCycles(dut.clk, 2)

#     # The following assersion is just an example of how to check the output values.
#     # Change it to match the actual expected output of your module:
#     assert dut.regA.value == 128
#     dut.bus.value = LogicArray("ZZZZZZZZ")
#     dut.load.value = 1
#     # Wait for two clock cycle to see the output values (one cycle fails)
#     await ClockCycles(dut.clk, 1)
#     dut.enable_output.value = 1
#     await ClockCycles(dut.clk, 2)
#     assert dut.bus.value == 128 
#     # Keep testing the module by changing the input values, waiting for
#     # one or more clock cycles, and asserting the expected output values.

CLOCK_PERIOD = 10  # 100 MHz
GLTEST = False
LocalTest = False

async def bus_values(dut):
    dut._log.info(f"GLTEST={GLTEST}")
    if (not GLTEST):
        dut._log.info(f"Current bus values: input={dut.ui_in.value}, bus={dut.user_project.bus.value}, output={dut.uo_out.value}")
    else:
        dut._log.info(f"Current bus values: input={dut.ui_in.value}, output={dut.uo_out.value}")

async def control_signal_values(dut):
    vals = dut.uio_in.value
    vals_out = dut.uio_out.value
    dut._log.info(f"Current control signal: {vals}")
    dut._log.info(f"Current control output: {vals_out}")
    dut._log.info(f"Current control signal values: output bus/n(regA)={read_control_signal_bit(vals,0)}, nLa={read_control_signal_bit(vals,1)}, nLb={read_control_signal_bit(vals,2)}, Ea={read_control_signal_bit(vals,3)}, Eu={read_control_signal_bit(vals,4)}, sub={read_control_signal_bit(vals,5)}, load_onto_bus={read_control_signal_bit(vals,6)}, CF={read_control_signal_bit(vals_out,6)}, ZF={read_control_signal_bit(vals_out,7)}")

def read_control_signal_bit(current, bit_index):
    if LocalTest:
        return current[7-bit_index]
    else:
        return current[bit_index]

def setbit(current, bit_index, bit_value):
    modified = current
    if LocalTest:
        modified[7-bit_index] = bit_value
    else:
        modified[bit_index] = bit_value
    return modified

async def determine_gltest(dut):
    global GLTEST
    dut._log.info("See if the test is being run for GLTEST")
    if hasattr(dut, 'VPWR'):
        dut._log.info("VPWR is Defined, may not equal to 1, GLTEST=TRUE")
        GLTEST = True
    else:
        GLTEST = False
        dut._log.info("VPWR is NOT Defined, GLTEST=False")
        assert dut.user_project.bus.value == dut.user_project.bus.value, "Something went terribly wrong"

async def init(dut):
    dut._log.info("Initialize clock")
    clock = Clock(dut.clk, CLOCK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())
    dut._log.info("Reset signals")
    await determine_gltest(dut) # For some unknown reason, determine_gltest sometimes executes after bus_vals, which makes 0 sense
    await bus_values(dut)
    dut.rst_n.value = 0
    dut.uio_in.value = LogicArray("111000ZZ")
    # dut.uio_in.value[0] = 1 # Output Bus/RegA
    # dut.uio_in.value[1] = 1 # RegA, nLa
    # dut.uio_in.value[2] = 1 # RegB, nLb
    # dut.uio_in.value[3] = 0 # RegA output, Ea
    # dut.uio_in.value[4] = 0 # ALU output, Eu
    # dut.uio_in.value[5] = 0 # Sub, sub
    dut.ui_in.value = LogicArray("00000000") # Bus

    dut._log.info("Wait for control signals to propogate (control signals and bus updates are falling edge)")
    await FallingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk) # <- THIS SHIT IS ANNOYING AF
    await RisingEdge(dut.clk) 
    await control_signal_values(dut)
    await bus_values(dut)
    if (not GLTEST):
        assert (dut.uo_out.value == "00000000") and (dut.user_project.bus.value == dut.uo_out.value), f"""Bus load failed: expected {LogicArray("00000000")}, got bus={dut.user_project.bus.value}, output={dut.uo_out.value}"""
    else:
        assert (dut.uo_out.value == "00000000" or dut.uo_out.value == "00000000"), f"""Bus load failed: expected {LogicArray("00000000")}, got output={dut.uo_out.value}"""


async def enable_regA_output(dut):
    dut._log.info("Flush bus to Hi-Z; Set RegA output to high")
    await RisingEdge(dut.clk)
    dut.uio_in.value = setbit(dut.uio_in.value, 6, 0)
    await RisingEdge(dut.clk)
    dut.uio_in.value = setbit(dut.uio_in.value, 3, 1)
    # dut.uio_in.value[3] = 1 # RegA output, Ea
    dut._log.info("Wait for Hi-Z to propogate to bus, and for control signals to update (Falling edge)")
    await FallingEdge(dut.clk)
    await control_signal_values(dut)
    if (not GLTEST):
        assert (read_control_signal_bit(dut.uio_in.value,3) == 1) and (dut.user_project.Ea.value == 1), "Ea did not get set"
        assert (dut.uo_out.value != "zzzzzzzz") and (dut.uo_out.value != "xxxxxxxx") and (dut.user_project.regA.value == dut.uo_out.value), f"RegA read failed: got {dut.uo_out.value}"
    else:
        assert (read_control_signal_bit(dut.uio_in.value,3) == 1), "Ea did not get set"
        assert (dut.uo_out.value != "zzzzzzzz") and (dut.uo_out.value != "xxxxxxxx"), f"RegA read failed: got {dut.uo_out.value}"
 


async def regAB_load_helper(dut, reg, val):
    dut._log.info(f"Set bus to {val}, bin: {val:#010b}")

    dut.ui_in.value = val # Bus
    controlsignal_value = setbit(dut.uio_in.value, 6, 1)

    dut._log.info("Wait for val to propogate to bus, and for control signals to update (Falling edge)")
    if reg.lower() == 'a':
        dut._log.info("Register A loading")
        dut.uio_in.value = setbit(controlsignal_value, 1, 0)
        # dut.uio_in.value[1] = 0
        # dut.nLa.value = 0
    elif reg.lower() == 'b':
        dut._log.info("Register B loading")
        dut.uio_in.value = setbit(controlsignal_value, 2, 0)
        # dut.uio_in.value[2] = 0
        # dut.nLb.value = 0
    else:
        assert False, f"Unknown register: {reg}"
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await bus_values(dut)
    await control_signal_values(dut)
    if (not GLTEST):
        assert (dut.uo_out.value == val) and (dut.user_project.bus.value == val), f"Bus load failed: expected {val}, got {dut.uo_out.value}"
    else:
        assert (dut.uo_out.value == val), f"Bus load failed: expected {val}, got {dut.uo_out.value}"
    dut._log.info("Wait for val to be latched to the registers")

    dut._log.info("Reset loading signals")
    controlsignal_value = setbit(dut.uio_in.value, 6, 0)
    controlsignal_value = setbit(controlsignal_value, 1, 1)
    dut.uio_in.value = setbit(controlsignal_value, 2, 1)
    
    await FallingEdge(dut.clk)
    dut.ui_in.value = LogicArray("00000000")
    #dut.uio_in.value[1] = 1
    #dut.uio_in.value[2] = 1
    # dut.nLa.value = 1
    # dut.nLa.value = 1

@cocotb.test()
async def accumulator_test_randint(dut):
    dut._log.info("Test the accumulator module loading with a rand int")
    await init(dut)
    test_value = randint(0,255)
    dut._log.info(f"Test load operation with val={test_value}, bin={test_value:#010b}")
    await regAB_load_helper(dut, 'a', test_value)
    dut.uio_in.value = setbit(dut.uio_in.value, 0, 0)
    # dut.uio_in.value[0] = 0 # Output RegA
    await FallingEdge(dut.clk)
    if (not GLTEST):
        assert (dut.uo_out.value == test_value) and (test_value == dut.user_project.regA.value), f"Accumulator output test: expected {test_value}, got regA={dut.user_project.regA.value} output={dut.uo_out.value}"
    else:
        assert (dut.uo_out.value == test_value), f"Accumulator output test: expected {test_value}, got output={dut.uo_out.value}"
    dut._log.info("Accumulator rand int module test completed successfully.")

@cocotb.test()
async def accumulator_test_randint_out(dut):
    dut._log.info("Test the accumulator module loading/reading with a rand int")
    await init(dut)
    
    test_value = randint(0,255)
    dut._log.info(f"Test load operation with val={test_value}, bin={test_value:#010b}")
    await regAB_load_helper(dut, 'a', test_value)
    # Test enable output functionality
    await enable_regA_output(dut)
    if (not GLTEST):
        assert (dut.uo_out.value == test_value) and (test_value == dut.user_project.regA.value), "Enable output failed: bus did not reflect loaded accumulator value"
    else:
        assert (dut.uo_out.value == test_value), "Enable output failed: bus did not reflect loaded accumulator value"
    dut._log.info("Accumulator enable output successful")
    dut.uio_in.value = setbit(dut.uio_in.value, 0, 0)
    # dut.uio_in.value[0] = 0 # Output RegA
    await FallingEdge(dut.clk)
    if (not GLTEST):
        dut._log.info(dut.user_project.regA.value)
        assert (dut.uo_out.value == test_value) and (test_value == dut.user_project.regA.value), f"Accumulator output test: expected {test_value}, got regA={dut.user_project.regA.value} output={dut.uo_out.value}"
    else:
        assert (dut.uo_out.value == test_value), f"Accumulator output test: expected {test_value}, got output={dut.uo_out.value}"
    dut._log.info("Accumulator rand int output module test completed successfully.")

@cocotb.test()
async def accumulator_test_shuffled_range(dut):
    dut._log.info("Test the accumulator module loading/reading with a shuffled range of 0-255")
    await init(dut)
    
    test_values = list(range(0,255))
    shuffle(test_values)
    test_values = test_values[:25]
    for test_value in test_values:
        dut._log.info(f"Test load operation with val={test_value}, bin={test_value:#010b}")
        await regAB_load_helper(dut, 'a', test_value)
        # Test enable output functionality
        await enable_regA_output(dut)
        if (not GLTEST):
            assert (dut.uo_out.value == test_value) and (test_value == dut.user_project.regA.value), "Enable output failed: bus did not reflect loaded accumulator value"
        else:
            assert (dut.uo_out.value == test_value), "Enable output failed: bus did not reflect loaded accumulator value"
        dut._log.info("Accumulator enable output successful")
        controlsignal_value = setbit(dut.uio_in.value, 0, 0)
        dut.uio_in.value = setbit(controlsignal_value, 3, 0)
        # dut.uio_in.value[0] = 0 # Output RegA
        await RisingEdge(dut.clk)
        if (not GLTEST):
            dut._log.info(dut.user_project.regA.value)
            assert (dut.uo_out.value == test_value) and (test_value == dut.user_project.regA.value), f"Accumulator output test: expected {test_value}, got regA={dut.user_project.regA.value} output={dut.uo_out.value}"
        else:
            assert (dut.uo_out.value == test_value), f"Accumulator output test: expected {test_value}, got output={dut.uo_out.value}"
        dut.uio_in.value = setbit(dut.uio_in.value, 0, 1)
        # dut.uio_in.value[0] = 1 # Output Bus
        await FallingEdge(dut.clk)
    
    dut._log.info("Accumulator shuffled range module test completed successfully.")

async def check_adder_operation(dut, operation, a, b):
    dut._log.info("Test addition/subtraction operations of the adder module")
    dut._log.info("Calculate expected result based on the operation")
    if operation == 0:
        expVal = (a + b) 
        expCF = int((expVal & 0x100) >> 8)
        expVal = expVal & 0xFF  # 8-bit overflow behavior for addition
        operation_name = "Addition"
    elif operation == 1:
        expVal = (a + ((b ^ 0xFF) + 1))
        expCF = (expVal & 0x100) >> 8
        expVal = expVal & 0xFF  # 8-bit underflow behavior for subtraction
        operation_name = "Subtraction"
    else:
        assert False, f"Unknown operation code: {operation}"
    expZF = int(expVal == 0)
    dut._log.info(f"Operation: {operation_name}, regA: {a} {a:#010b}, regB: {b} {b:#010b}")
    dut._log.info(f"Expected result: {expVal}, bin: {expVal:#010b}, ZF: {expZF}, CF: {expCF}") 
    # Wait for result on the bus
    controlsignal_value = setbit(dut.uio_in.value, 5, operation)
    dut.uio_in.value = setbit(controlsignal_value, 4, 1)
    await RisingEdge(dut.clk)
    await control_signal_values(dut)
    if (not GLTEST):
        assert (dut.user_project.regA.value == a), f"RegA did not get set: expected {a}, got {dut.user_project.regA.value}"
        assert (dut.user_project.regB.value == b), f"RegB did not get set: expected {b}, got {dut.user_project.regB.value}"
        assert (read_control_signal_bit(dut.uio_in.value,4) == 1) and (dut.user_project.Eu.value == 1), "Eu did not get set"
        assert (dut.uo_out.value == expVal) and (expVal == dut.user_project.bus.value), f"Enable adder output failed: expected {expVal} {expVal:#010b}, got bus={dut.user_project.bus.value}, output={dut.uo_out.value}"
    else:
        assert (read_control_signal_bit(dut.uio_in.value,4) == 1), "Eu did not get set"
        assert (dut.uo_out.value == expVal), f"Enable adder output failed: expected {expVal} {expVal:#010b}, got output={dut.uo_out.value}"
    await FallingEdge(dut.clk)
    if (not GLTEST):
        assert (read_control_signal_bit(dut.uio_out.value,6) == expCF) and (dut.user_project.CF.value == expCF), f"Carry flag failed: expected {expCF}, got {dut.user_project.CF.value}"
        assert dut.user_project.CF.value == expCF, f"Carry flag failed: expected {expCF}, got {dut.user_project.CF.value}"
        assert (read_control_signal_bit(dut.uio_out.value,7) == expZF) and (dut.user_project.ZF.value == expZF), f"Zero flag failed: expected {expZF}, got {dut.user_project.ZF.value}"
    else:
        assert (read_control_signal_bit(dut.uio_out.value,6) == expCF), f"Carry flag failed: expected {expCF}, got {dut.uo_out.value}"
        assert (read_control_signal_bit(dut.uio_out.value,7) == expZF), f"Zero flag failed: expected {expZF}, got {dut.uo_out.value}"
        
    # Verify and log
    dut.uio_in.value = setbit(dut.uio_in.value, 4, 0)
    await FallingEdge(dut.clk)
    dut._log.info(f"{operation_name} operation successful: a={a}, b={b}, result={expVal}")


@cocotb.test()
async def adder_test_addition_range(dut):
    dut._log.info("Test the adder module adding/subtracting with a shuffled range of 0-255")
    await init(dut)

    test_regA_values = list(range(0,255))
    shuffle(test_regA_values)
    test_regA_values = test_regA_values[:50]
    
    test_regB_values = list(range(0,255))
    shuffle(test_regB_values)
    test_regB_values = test_regB_values[:50]
    
    operation_dict = {0: "Addition", 1: "Subtraction"}

    for regA_val in test_regA_values:
        for regB_val in test_regB_values:
            operation = 0
            dut._log.info(f"Testing {operation_dict[operation]} operation for regA={regA_val}, regA_bin={regA_val:#010b} and regB={regB_val}, regB_bin={regB_val:#010b}")
            await regAB_load_helper(dut, 'a', regA_val)
            await FallingEdge(dut.clk)
            await regAB_load_helper(dut, 'b', regB_val)
            dut.uio_in.value = setbit(dut.uio_in.value, 5, operation)
            
            await check_adder_operation(dut, operation, regA_val, regB_val)            
    dut._log.info("Adder module test completed successfully.")

@cocotb.test()
async def adder_test_subtraction_range(dut):
    dut._log.info("Test the adder module adding/subtracting with a shuffled range of 0-255")
    await init(dut)

    test_regA_values = list(range(0,255))
    shuffle(test_regA_values)
    test_regA_values = test_regA_values[:50]
    
    test_regB_values = list(range(0,255))
    shuffle(test_regB_values)
    test_regB_values = test_regB_values[:50]
    
    operation_dict = {0: "Addition", 1: "Subtraction"}

    for regA_val in test_regA_values:
        for regB_val in test_regB_values:
            operation = 1
            dut._log.info(f"Testing {operation_dict[operation]} operation for regA={regA_val}, regA_bin={regA_val:#010b} and regB={regB_val}, regB_bin={regB_val:#010b}")
            await regAB_load_helper(dut, 'a', regA_val)
            await FallingEdge(dut.clk)
            await regAB_load_helper(dut, 'b', regB_val)
            dut.uio_in.value = setbit(dut.uio_in.value, 5, operation)
            await check_adder_operation(dut, operation, regA_val, regB_val)            
    dut._log.info("Adder module test completed successfully.")

@cocotb.test()
async def adder_test_addsub_range(dut):
    dut._log.info("Test the adder module adding/subtracting with a shuffled range of 0-255")
    await init(dut)

    test_regA_values = list(range(0,255))
    shuffle(test_regA_values)
    test_regA_values = test_regA_values[:50]
    
    test_regB_values = list(range(0,255))
    shuffle(test_regB_values)
    test_regB_values = test_regB_values[:50]
    
    operation_dict = {0: "Addition", 1: "Subtraction"}

    for regA_val in test_regA_values:
        for regB_val in test_regB_values:
            operation = randint(0,1)
            dut._log.info(f"Testing {operation_dict[operation]} operation for regA={regA_val}, regA_bin={regA_val:#010b} and regB={regB_val}, regB_bin={regB_val:#010b}")
            await regAB_load_helper(dut, 'a', regA_val)
            await FallingEdge(dut.clk)
            await regAB_load_helper(dut, 'b', regB_val)
            dut.uio_in.value = setbit(dut.uio_in.value, 5, operation)
            await check_adder_operation(dut, operation, regA_val, regB_val)            
    dut._log.info("Adder module test completed successfully.")
