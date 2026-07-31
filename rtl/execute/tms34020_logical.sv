`timescale 1ns/1ps
`default_nettype none

module tms34020_logical (
    input  tms34020_pkg::tms34020_logical_op_t operation_i,
    input  logic [31:0]                        source_i,
    input  logic [31:0]                        destination_i,
    output logic [31:0]                        result_o,
    output logic                               status_z_o
);

    import tms34020_pkg::*;

    always_comb begin
        unique case (operation_i)
            TMS34020_LOGICAL_AND: begin
                result_o = source_i & destination_i;
            end

            TMS34020_LOGICAL_ANDN: begin
                result_o = ~source_i & destination_i;
            end

            TMS34020_LOGICAL_OR: begin
                result_o = source_i | destination_i;
            end

            TMS34020_LOGICAL_XOR: begin
                result_o = source_i ^ destination_i;
            end

            default: begin
                result_o = 32'd0;
            end
        endcase
        status_z_o = result_o == 32'd0;
    end

endmodule

`default_nettype wire
