// Matrix Multiplier DUT

`timescale 1ns/1ps

module matrix_multiplier();

parameter   DATA_WIDTH = 8,
            A_ROWS = 8,
            B_COLUMNS = 5,
            A_COLUMNS_B_ROWS = 4;

localparam C_DATA_WIDTH = (2*DATA_WIDTH)+$clog2(A_COLUMNS_B_ROWS);

reg                         clk;
reg                         reset;

reg                         i_valid;
reg                         o_valid;

//  DATA BITS                   ROWS                        COLUMNS
reg [DATA_WIDTH-1:0]        i_A [0 : A_ROWS-1]              [0 : A_COLUMNS_B_ROWS-1];
reg [DATA_WIDTH-1:0]        i_B [0 : A_COLUMNS_B_ROWS-1]    [0 : B_COLUMNS-1];
reg [C_DATA_WIDTH-1 : 0]    o_C [0 : A_ROWS-1]              [0 : B_COLUMNS-1];

reg [C_DATA_WIDTH-1:0] C_RESULT;

integer i;
integer j;
integer k;

    always @(posedge clk) begin
        if (reset) begin
            C_RESULT = 0;
            o_valid <= 0;
        end else if (i_valid) begin
            for (i=0; i < A_ROWS; i=i+1) begin
                for (j=0; j < B_COLUMNS; j=j+1) begin
                    C_RESULT = 0;
                    for (k=0; k < A_COLUMNS_B_ROWS; k=k+1) begin
                        C_RESULT = C_RESULT + (i_A[i][k] * i_B[k][j]);
                    end
                    o_C[i][j] <= C_RESULT;
                end
            end

            o_valid <= 1;
        end else begin
            o_valid <= 0;
        end
    end

    // Dump waves
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(1, matrix_multiplier);
    end

endmodule
