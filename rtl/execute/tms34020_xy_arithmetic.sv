`timescale 1ns/1ps
`default_nettype none

module tms34020_xy_arithmetic (
    input  tms34020_pkg::tms34020_xy_op_t operation_i,
    input  logic [31:0]                    source_i,
    input  logic [31:0]                    destination_i,
    output logic [31:0]                    result_o,
    output logic [3:0]                     status_nczv_o
);

    import tms34020_pkg::*;

    logic [15:0] result_x;
    logic [15:0] result_y;

    always_comb begin
        result_x = destination_i[15:0] + source_i[15:0];
        result_y = destination_i[31:16] + source_i[31:16];
        status_nczv_o = {
            result_x == 16'd0,
            result_y[15],
            result_y == 16'd0,
            result_x[15]
        };

        if (operation_i == TMS34020_XY_SUB) begin
            result_x = destination_i[15:0] - source_i[15:0];
            result_y = destination_i[31:16] - source_i[31:16];
            status_nczv_o = {
                source_i[15:0] == destination_i[15:0],
                source_i[31:16] > destination_i[31:16],
                source_i[31:16] == destination_i[31:16],
                source_i[15:0] > destination_i[15:0]
            };
        end

        result_o = {result_y, result_x};
    end

endmodule

`default_nettype wire
