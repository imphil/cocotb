// Matrix Multiplier DUT

`timescale 1ns / 1ps

module matrix_multiplier ();

  parameter int DATA_WIDTH = 8;
  parameter int A_ROWS = 8;
  parameter int B_COLUMNS = 5;
  parameter int A_COLUMNS_B_ROWS = 4;

  localparam C_DATA_WIDTH = (2 * DATA_WIDTH) + $clog2(A_COLUMNS_B_ROWS);

  reg clk_i;
  reg reset_i;

  reg valid_i;
  reg valid_o;

  reg [DATA_WIDTH-1:0]   a_i[A_ROWS][A_COLUMNS_B_ROWS];
  reg [DATA_WIDTH-1:0]   b_i[A_COLUMNS_B_ROWS][B_COLUMNS];
  reg [C_DATA_WIDTH-1:0] c_o[A_ROWS][B_COLUMNS];

  reg [C_DATA_WIDTH-1:0] c_element;


  integer i, j, k;

  always @(*) begin
    for (i = 0; i < A_ROWS; i = i + 1) begin
      for (j = 0; j < B_COLUMNS; j = j + 1) begin
        c_element = 0;
        for (k = 0; k < A_COLUMNS_B_ROWS; k = k + 1) begin
          c_element = c_element + (a_i[i][k] * b_i[k][j]);
        end
        c_o[i][j] = c_element;
      end
    end
  end

  always @(posedge clk_i) begin
    if (reset_i) begin
      valid_o <= 1'b0;
    end else begin
      valid_o <= valid_i;
    end
  end

  // Dump waves
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(1, matrix_multiplier);
  end

endmodule
