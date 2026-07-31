`timescale 1ns/1ps
`default_nettype none

module tms34020_bit_test (
    input  logic [31:0] value_i,
    input  logic [4:0]  bit_index_i,
    output logic        status_z_o
);

    always_comb begin
        status_z_o = ~value_i[bit_index_i];
    end

endmodule

`default_nettype wire
