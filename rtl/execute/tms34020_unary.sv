`timescale 1ns/1ps
`default_nettype none

module tms34020_unary (
    input  tms34020_pkg::tms34020_unary_op_t operation_i,
    input  logic [31:0]                      destination_i,
    input  logic                             borrow_i,
    output logic [31:0]                      result_o,
    output logic [3:0]                       status_nczv_o,
    output logic [3:0]                       status_write_mask_o
);

    import tms34020_pkg::*;

    logic [31:0] negated;
    logic [31:0] negated_with_borrow;

    always_comb begin
        negated = (~destination_i) + 32'd1;
        negated_with_borrow = negated - {31'd0, borrow_i};
        result_o = 32'd0;
        status_nczv_o = 4'b0000;
        status_write_mask_o = 4'b0000;

        unique case (operation_i)
            TMS34020_UNARY_ABS: begin
                result_o = destination_i[31] ? negated : destination_i;
                status_nczv_o[3] = negated[31];
                status_nczv_o[1] = destination_i == 32'd0;
                status_nczv_o[0] = destination_i == 32'h8000_0000;
                status_write_mask_o = 4'b1011;
            end

            TMS34020_UNARY_NEG: begin
                result_o = negated;
                status_nczv_o[3] = negated[31];
                status_nczv_o[2] = destination_i != 32'd0;
                status_nczv_o[1] = negated == 32'd0;
                status_nczv_o[0] = destination_i == 32'h8000_0000;
                status_write_mask_o = 4'b1111;
            end

            TMS34020_UNARY_NEGB: begin
                result_o = negated_with_borrow;
                status_nczv_o[3] = negated_with_borrow[31];
                status_nczv_o[2] =
                    (destination_i != 32'd0) || borrow_i;
                status_nczv_o[1] = negated_with_borrow == 32'd0;
                status_nczv_o[0] =
                    destination_i[31] && negated_with_borrow[31];
                status_write_mask_o = 4'b1111;
            end

            TMS34020_UNARY_NOT: begin
                result_o = ~destination_i;
                status_nczv_o[1] = result_o == 32'd0;
                status_write_mask_o = 4'b0010;
            end

            default: begin
                result_o = 32'd0;
                status_nczv_o = 4'b0000;
                status_write_mask_o = 4'b0000;
            end
        endcase
    end

endmodule

`default_nettype wire
