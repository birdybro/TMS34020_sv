`timescale 1ns/1ps
`default_nettype none

module tms34020_field_extend (
    input  logic [31:0] value_i,
    input  logic [4:0]  encoded_size_i,
    input  logic        sign_extend_i,
    output logic [31:0] result_o,
    output logic        status_n_o,
    output logic        status_z_o
);

    logic [5:0] field_size;
    logic [4:0] sign_bit_index;
    logic [31:0] field_mask;
    logic [31:0] zero_extended;

    always_comb begin
        field_size = {1'b0, encoded_size_i};
        if (encoded_size_i == 5'd0) begin
            field_size = 6'd32;
        end
        sign_bit_index = field_size[4:0] - 5'd1;

        field_mask = 32'hFFFF_FFFF;
        if (field_size != 6'd32) begin
            field_mask =
                32'hFFFF_FFFF >> (6'd32 - field_size);
        end

        zero_extended = value_i & field_mask;
        result_o = zero_extended;
        if (
            sign_extend_i &&
            zero_extended[sign_bit_index]
        ) begin
            result_o = zero_extended | ~field_mask;
        end

        status_n_o = result_o[31];
        status_z_o = result_o == 32'd0;
    end

endmodule

`default_nettype wire
