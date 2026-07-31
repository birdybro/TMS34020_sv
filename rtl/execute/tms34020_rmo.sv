`timescale 1ns/1ps
`default_nettype none

module tms34020_rmo (
    input  logic [31:0] source_i,
    output logic [31:0] result_o,
    output logic        status_z_o
);

    logic found;
    integer bit_index;

    always_comb begin
        result_o = 32'd0;
        status_z_o = source_i == 32'd0;
        found = 1'b0;
        for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
            if (!found && source_i[bit_index]) begin
                result_o = {27'd0, bit_index[4:0]};
                found = 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
