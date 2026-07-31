`timescale 1ns/1ps
`default_nettype none

module tms34020_cmpk (
    input  logic [31:0] destination_i,
    input  logic [4:0]  encoded_constant_i,
    output logic [31:0] compare_result_o,
    output logic        status_n_o,
    output logic        status_c_o,
    output logic        status_z_o,
    output logic        status_v_o
);

    logic [31:0] constant_value;

    always_comb begin
        if (encoded_constant_i == 5'd0) begin
            constant_value = 32'd32;
        end else begin
            constant_value = {27'd0, encoded_constant_i};
        end

        compare_result_o = destination_i - constant_value;
        status_n_o = compare_result_o[31];
        status_c_o = destination_i < constant_value;
        status_z_o = compare_result_o == 32'd0;
        status_v_o =
            ((destination_i[31] != constant_value[31]) &&
             (destination_i[31] != compare_result_o[31]));
    end

endmodule

`default_nettype wire
