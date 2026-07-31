`timescale 1ns/1ps
`default_nettype none

module tms34020_status (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic        write_enable_i,
    input  logic [31:0] write_data_i,
    input  logic [31:0] write_mask_i,
    output logic [31:0] status_o
);

    import tms34020_pkg::*;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            status_o <= TMS34020_ST_RESET;
        end else if (write_enable_i) begin
            status_o <=
                (status_o & ~write_mask_i) |
                (write_data_i & write_mask_i);
        end
    end

endmodule

`default_nettype wire
