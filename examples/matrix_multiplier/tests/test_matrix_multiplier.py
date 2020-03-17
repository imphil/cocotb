import math
import os
from random import getrandbits

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.monitors import BusMonitor
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.triggers import RisingEdge, ReadOnly

NUM_SAMPLES = int(os.environ.get('NUM_SAMPLES', 3000))
DATA_WIDTH = int(os.environ['DATA_WIDTH'])
A_ROWS = int(os.environ['A_ROWS'])
B_COLUMNS = int(os.environ['B_COLUMNS'])
A_COLUMNS_B_ROWS = int(os.environ['A_COLUMNS_B_ROWS'])

MULTI_DIMENSIONAL_ARRAYS = not cocotb.SIM_NAME.lower().startswith(("icarus", "ghdl"))

if MULTI_DIMENSIONAL_ARRAYS:
    def get_matrix_value(signal, rows, cols):
        return signal.value

    def set_matrix_value(signal, matrix_value):
        signal <= matrix_value
else:
    def get_matrix_value(signal, rows, cols):
        return [
            [
                signal[(i * cols) + j].value
                for j in range(cols)
            ]
            for i in range(rows)
        ]

    def set_matrix_value(signal, matrix_value):
        for i, row in enumerate(matrix_value):
            for j, value in enumerate(row):
                signal[(i * len(row)) + j] <= value


class MatrixMonitor(BusMonitor):
    """Base class for monitoring inputs/outputs of Matrix Multiplier."""
    def __init__(self, dut, callback=None, event=None):
        BusMonitor.__init__(self, dut, self._prefix, dut.clk, callback=callback, event=event)


class MatrixInMonitor(MatrixMonitor):
    """Monitor inputs to Matrix Multiplier module and generate expected results
    for each multiplication operation.
    """
    _prefix = "i"
    _signals = ["A", "B", "valid"]

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            await ReadOnly()

            if self.bus.valid.value:
                a_matrix = get_matrix_value(self.bus.A, A_ROWS, A_COLUMNS_B_ROWS)
                b_matrix = get_matrix_value(self.bus.B, A_COLUMNS_B_ROWS, B_COLUMNS)

                # Calculate the expected result of C
                c_expected = [
                    [
                        BinaryValue(
                            value=sum(
                                [
                                    a_matrix[i][n] * b_matrix[n][j]
                                    for n in range(A_COLUMNS_B_ROWS)
                                ]
                            ),
                            n_bits=(DATA_WIDTH * 2) + math.ceil(math.log2(A_COLUMNS_B_ROWS)),
                            bigEndian=False
                        )
                        for j in range(B_COLUMNS)
                    ]
                    for i in range(A_ROWS)
                ]

                self._recv(c_expected)


class MatrixOutMonitor(MatrixMonitor):
    """Monitor outputs from Matrix Multiplier module and capture resulting matrix
    for each multiplication operation.
    """
    _prefix = "o"
    _signals = ["C", "valid"]

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            await ReadOnly()

            if self.bus.valid.value:
                c_actual = get_matrix_value(self.bus.C, A_ROWS, B_COLUMNS)
                self._recv(c_actual)


@cocotb.coroutine
async def test_multiply(dut, a_data, b_data):
    """Test multiplication of many matrices."""

    cocotb.fork(Clock(dut.clk, 5, units='ns').start())

    dut._log.info("Multi-Dimensional Array support: %s", MULTI_DIMENSIONAL_ARRAYS)
    expected_output = []

    def add_expected(transaction):
        expected_output.append(transaction)

    in_monitor = MatrixInMonitor(dut, callback=add_expected)
    out_monitor = MatrixOutMonitor(dut)

    scoreboard = Scoreboard(dut)
    scoreboard.add_interface(out_monitor, expected_output)

    # Initial values
    dut.i_valid <= 0
    set_matrix_value(dut.i_A, next(gen_a(1, lambda x: 0)))
    set_matrix_value(dut.i_B, next(gen_b(1, lambda x: 0)))

    # Reset DUT
    dut.reset <= 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.reset <= 0

    # Do multiplication
    for A, B in zip(a_data(), b_data()):
        await RisingEdge(dut.clk)
        set_matrix_value(dut.i_A, A)
        set_matrix_value(dut.i_B, B)
        dut.i_valid <= 1

        await RisingEdge(dut.clk)
        dut.i_valid <= 0

    await RisingEdge(dut.clk)

    raise scoreboard.result


def gen_matrix(func, rows, cols):
    return [[func(DATA_WIDTH) for col in range(cols)] for row in range(rows)]

def gen_a(num_samples=NUM_SAMPLES, func=getrandbits):
    """Generate random matrix data for A"""
    for i in range(num_samples):
        yield gen_matrix(func, A_ROWS, A_COLUMNS_B_ROWS)

def gen_b(num_samples=NUM_SAMPLES, func=getrandbits):
    """Generate random matrix data for B"""
    for i in range(num_samples):
        yield gen_matrix(func, A_COLUMNS_B_ROWS, B_COLUMNS)

factory = TestFactory(test_multiply)
factory.add_option('a_data', [gen_a])
factory.add_option('b_data', [gen_b])
factory.generate_tests()
