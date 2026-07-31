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

    import tms34020_pkg::*;

    logic [3:0] status_nczv;

    tms34020_xy_arithmetic arithmetic (
        .operation_i(TMS34020_XY_ADD),
        .source_i(immediate_i),
        .destination_i(destination_i),
        .result_o(result_o),
        .status_nczv_o(status_nczv)
    );

    always_comb begin
        status_n_o = status_nczv[3];
        status_c_o = status_nczv[2];
        status_z_o = status_nczv[1];
        status_v_o = status_nczv[0];
    end

endmodule

`default_nettype wire
