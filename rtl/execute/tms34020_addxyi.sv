`timescale 1ns/1ps
`default_nettype none

module tms34020_addxyi (
    input  logic [31:0] destination_i,
    input  logic [31:0] immediate_i,
    output logic [31:0] result_o,
    output logic        status_n_o,
    output logic        status_c_o,
    output logic        status_z_o,
    output logic        status_v_o
);

    logic [15:0] result_x;
    logic [15:0] result_y;

    always_comb begin
        result_x = destination_i[15:0] + immediate_i[15:0];
        result_y = destination_i[31:16] + immediate_i[31:16];
        result_o = {result_y, result_x};

        status_n_o = (result_x == 16'd0);
        status_c_o = result_y[15];
        status_z_o = (result_y == 16'd0);
        status_v_o = result_x[15];
    end

endmodule

`default_nettype wire
