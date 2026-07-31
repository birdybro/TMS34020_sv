`timescale 1ns/1ps
`default_nettype none

module tms34020_binary_arithmetic (
    input  tms34020_pkg::tms34020_binary_op_t operation_i,
    input  logic [31:0]                       source_i,
    input  logic [31:0]                       destination_i,
    input  logic                              carry_or_borrow_i,
    output logic [31:0]                       result_o,
    output logic [3:0]                        status_nczv_o,
    output logic                              register_write_enable_o
);

    import tms34020_pkg::*;

    logic add_carry_in;
    logic subtract_borrow_in;
    logic [32:0] addition;
    logic [31:0] addition_low;
    logic [32:0] subtraction;
    logic [31:0] subtraction_low;

    always_comb begin
        add_carry_in =
            (operation_i == TMS34020_BINARY_ADDC) &&
            carry_or_borrow_i;
        subtract_borrow_in =
            (operation_i == TMS34020_BINARY_SUBB) &&
            carry_or_borrow_i;

        addition =
            {1'b0, destination_i} +
            {1'b0, source_i} +
            {32'd0, add_carry_in};
        addition_low =
            {1'b0, destination_i[30:0]} +
            {1'b0, source_i[30:0]} +
            {31'd0, add_carry_in};
        subtraction =
            {1'b0, destination_i} +
            {1'b0, ~source_i} +
            {32'd0, ~subtract_borrow_in};
        subtraction_low =
            {1'b0, destination_i[30:0]} +
            {1'b0, ~source_i[30:0]} +
            {31'd0, ~subtract_borrow_in};

        result_o = 32'd0;
        status_nczv_o = 4'b0000;
        register_write_enable_o = 1'b0;

        unique case (operation_i)
            TMS34020_BINARY_ADD,
            TMS34020_BINARY_ADDC: begin
                result_o = addition[31:0];
                status_nczv_o[3] = addition[31];
                status_nczv_o[2] = addition[32];
                status_nczv_o[1] = addition[31:0] == 32'd0;
                status_nczv_o[0] =
                    (addition_low >= 32'h8000_0000) ^ addition[32];
                register_write_enable_o = 1'b1;
            end

            TMS34020_BINARY_SUB,
            TMS34020_BINARY_SUBB,
            TMS34020_BINARY_CMP: begin
                result_o = subtraction[31:0];
                status_nczv_o[3] = subtraction[31];
                status_nczv_o[2] = ~subtraction[32];
                status_nczv_o[1] = subtraction[31:0] == 32'd0;
                status_nczv_o[0] =
                    (subtraction_low >= 32'h8000_0000) ^
                    subtraction[32];
                register_write_enable_o =
                    operation_i != TMS34020_BINARY_CMP;
            end

            default: begin
                result_o = 32'd0;
                status_nczv_o = 4'b0000;
                register_write_enable_o = 1'b0;
            end
        endcase
    end

endmodule

`default_nettype wire
