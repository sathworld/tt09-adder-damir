import cocotb
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.types.logic import Logic
from cocotb.types.logic_array import LogicArray
import cocotb.utils

CLOCK_PERIOD = 20  # 50 MHz

async def clock_gen(clk):
    clock = Clock(clk, CLOCK_PERIOD, units="ns")
    cocotb.start_soon(clock.start())

@cocotb.test()
async def accumulator_test(dut):
    """ Test the accumulator module """

    cocotb.start_soon(clock_gen(dut.clk))

    # Reset signals
    dut.load.value = 1
    dut.enable_output.value = 0
    dut.bus.value = LogicArray("ZZZZZZZZ")
    await ClockCycles(dut.clk, 10)
    # Test load operation
    test_value = 20
    dut.bus.value = test_value
    await ClockCycles(dut.clk, 10)
    assert dut.bus.value == test_value, f"Bus test: expected {test_value}, got {dut.regA.value}"
    await FallingEdge(dut.clk)
    dut.load.value = 0
    await FallingEdge(dut.clk)
    dut.load.value = 1
    # Allow a cycle for loading to complete
    # Check accumulator load result
    assert dut.regA.value == test_value, f"Accumulator load test: expected {test_value}, got {dut.regA.value}"

    # Test enable output functionality
    dut.enable_output.value = 1
    await RisingEdge(dut.clk)
    assert dut.bus.value == test_value, "Enable output failed: bus did not reflect accumulator value"
    dut._log.info("Accumulator enable output successful")

    dut._log.info("Accumulator module test completed successfully.")

async def check_adder_operation(dut, operation, a, b, timeout_ns=200):
    """ Helper function to test addition and subtraction operations of the adder module """
    
    # Set up inputs
    dut.reg_a.value = a
    dut.reg_b.value = b
    dut.sub.value = operation
    dut.enable_output.value = 1

    # Calculate expected result based on the operation
    if operation == 0:
        expected_result = (a + b) & 0xFF  # 8-bit overflow behavior for addition
        operation_name = "Addition"
    elif operation == 1:
        expected_result = (a - b) & 0xFF  # 8-bit underflow behavior for subtraction
        operation_name = "Subtraction"
    else:
        assert False, f"Unknown operation code: {operation}"

    # Start timing
    start_time = cocotb.utils.get_sim_time()

    # Wait for result on the bus
    result_stabilized = False
    while not result_stabilized:
        await RisingEdge(dut.clk)
        if dut.bus.value == expected_result:
            result_stabilized = True
            break
        if cocotb.utils.get_sim_time() - start_time >= timeout_ns:
            assert False, f"Timeout: {operation_name} did not complete within {timeout_ns} ns."

    # End timing
    end_time = cocotb.utils.get_sim_time()
    time_taken = end_time - start_time

    # Verify and log
    result = dut.bus.value
    assert result == expected_result, f"Test failed for {operation_name} with a={a}, b={b}. Expected {expected_result}, got {result}."
    dut._log.info(f"{operation_name} operation successful: a={a}, b={b}, result={result} (Time taken: {time_taken} ns)")

@cocotb.test()
async def adder_test(dut):
    """ Test the add_sub_8bit_sync module """

    cocotb.start_soon(clock_gen(dut.clk))

    # Reset signals
    dut.enable_output.value = 0
    dut.reg_a.value = 0
    dut.reg_b.value = 0
    dut.sub.value = 0

    # Test addition and subtraction operations
    await check_adder_operation(dut, operation=0, a=20, b=15)
    await check_adder_operation(dut, operation=1, a=50, b=25)
    await check_adder_operation(dut, operation=0, a=200, b=100)
    await check_adder_operation(dut, operation=1, a=10, b=20)

    # Test zero flag functionality
    dut.reg_a.value = 10
    dut.reg_b.value = 10
    dut.sub.value = 1
    dut.enable_output.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)  # Allow time for zero flag update

    # Check zero flag result
    if dut.ZF.value.integer == 1:
        dut._log.info("Zero flag correctly set for result = 0")
    else:
        assert False, "Zero flag failed: expected ZF=1 for zero result"

    dut._log.info("Adder module test completed successfully.")

# Main test entry point
if __name__ == "__main__":
    # Run the accumulator test
    cocotb.run_all_tests()