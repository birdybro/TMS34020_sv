`timescale 1ns/1ps
`default_nettype none

module tms34020_regfile (
    input  logic        clk_i,
    input  logic        reset_i,

    input  logic        write_enable_i,
    input  logic        write_file_i,
    input  logic [3:0]  write_index_i,
    input  logic [31:0] write_data_i,

    input  logic        read0_file_i,
    input  logic [3:0]  read0_index_i,
    output logic [31:0] read0_data_o,

    input  logic        read1_file_i,
    input  logic [3:0]  read1_index_i,
    output logic [31:0] read1_data_o,

    output logic [31:0] sp_o
);

    logic [31:0] a_regs [0:14];
    logic [31:0] b_regs [0:14];
    logic [31:0] sp;
    integer register_index;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            for (register_index = 0;
                 register_index < 15;
                 register_index = register_index + 1) begin
                a_regs[register_index] <= 32'd0;
                b_regs[register_index] <= 32'd0;
            end
            sp <= 32'd0;
        end else if (write_enable_i) begin
            if (write_index_i == 4'd15) begin
                sp <= write_data_i;
            end else if (write_file_i) begin
                b_regs[write_index_i] <= write_data_i;
            end else begin
                a_regs[write_index_i] <= write_data_i;
            end
        end
    end

    always_comb begin
        if (read0_index_i == 4'd15) begin
            read0_data_o = sp;
        end else if (read0_file_i) begin
            read0_data_o = b_regs[read0_index_i];
        end else begin
            read0_data_o = a_regs[read0_index_i];
        end

        if (read1_index_i == 4'd15) begin
            read1_data_o = sp;
        end else if (read1_file_i) begin
            read1_data_o = b_regs[read1_index_i];
        end else begin
            read1_data_o = a_regs[read1_index_i];
        end
        sp_o = sp;
    end

endmodule

`default_nettype wire
