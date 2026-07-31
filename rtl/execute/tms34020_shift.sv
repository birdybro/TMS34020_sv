`timescale 1ns/1ps
`default_nettype none

module tms34020_shift (
    input  tms34020_pkg::tms34020_shift_op_t operation_i,
    input  logic [31:0]                      value_i,
    input  logic [4:0]                       count_i,
    output logic [31:0]                      result_o,
    output logic [3:0]                       status_nczv_o,
    output logic [3:0]                       status_write_mask_o
);

    import tms34020_pkg::*;

    logic signed [31:0] signed_value;
    logic [4:0] left_carry_index;
    logic [4:0] right_carry_index;
    logic [4:0] sign_mask_shift;
    logic [31:0] sign_difference;
    logic [31:0] sign_window_mask;

    always_comb begin
        signed_value = $signed(value_i);
        left_carry_index = 5'd0 - count_i;
        right_carry_index = count_i - 5'd1;
        sign_mask_shift = 5'd31 - count_i;
        sign_difference = value_i ^ {32{value_i[31]}};
        sign_window_mask = 32'hFFFF_FFFF << sign_mask_shift;

        result_o = value_i;
        status_nczv_o = 4'b0000;
        status_write_mask_o = 4'b0000;

        unique case (operation_i)
            TMS34020_SHIFT_SLA: begin
                result_o = value_i << count_i;
                status_nczv_o[3] = result_o[31];
                status_nczv_o[2] =
                    (count_i == 5'd0)
                    ? 1'b0
                    : value_i[left_carry_index];
                status_nczv_o[1] = result_o == 32'd0;
                status_nczv_o[0] =
                    (count_i == 5'd0)
                    ? 1'b0
                    : |(sign_difference & sign_window_mask);
                status_write_mask_o = 4'b1111;
            end

            TMS34020_SHIFT_SLL: begin
                result_o = value_i << count_i;
                status_nczv_o[2] =
                    (count_i == 5'd0)
                    ? 1'b0
                    : value_i[left_carry_index];
                status_nczv_o[1] = result_o == 32'd0;
                status_write_mask_o = 4'b0110;
            end

            TMS34020_SHIFT_SRA: begin
                result_o = signed_value >>> count_i;
                status_nczv_o[3] = result_o[31];
                status_nczv_o[2] =
                    (count_i == 5'd0)
                    ? 1'b0
                    : value_i[right_carry_index];
                status_nczv_o[1] = result_o == 32'd0;
                status_write_mask_o = 4'b1110;
            end

            TMS34020_SHIFT_SRL: begin
                result_o = value_i >> count_i;
                status_nczv_o[2] =
                    (count_i == 5'd0)
                    ? 1'b0
                    : value_i[right_carry_index];
                status_nczv_o[1] = result_o == 32'd0;
                status_write_mask_o = 4'b0110;
            end

            default: begin
                result_o = value_i;
                status_nczv_o = 4'b0000;
                status_write_mask_o = 4'b0000;
            end
        endcase
    end

endmodule

`default_nettype wire
