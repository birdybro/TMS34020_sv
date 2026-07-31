`timescale 1ns/1ps
`default_nettype none

module tms34020_pixel_size_ops (
    input  logic [15:0] register_low_i,
    input  logic [15:0] psize_i,
    input  logic        exchange_i,
    output logic [31:0] register_result_o,
    output logic        psize_write_enable_o,
    output logic [15:0] psize_write_data_o
);

    always_comb begin
        register_result_o = {16'd0, psize_i};
        psize_write_enable_o = exchange_i;
        psize_write_data_o = exchange_i ? register_low_i : 16'd0;
    end

endmodule

`default_nettype wire
