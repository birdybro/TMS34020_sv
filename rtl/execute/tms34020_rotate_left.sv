`timescale 1ns/1ps
`default_nettype none

module tms34020_rotate_left (
    input  logic [31:0] value_i,
    input  logic [4:0]  count_i,
    output logic [31:0] result_o,
    output logic        status_c_o,
    output logic        status_z_o
);

    logic [5:0] right_count;

    always_comb begin
        result_o = value_i;
        right_count = 6'd0;

        if (count_i != 5'd0) begin
            right_count = 6'd32 - {1'b0, count_i};
            result_o =
                (value_i << count_i) |
                (value_i >> right_count);
        end

        status_c_o = (count_i == 5'd0) ? 1'b0 : result_o[0];
        status_z_o = result_o == 32'd0;
    end

endmodule

`default_nettype wire
