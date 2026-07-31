`timescale 1ns/1ps
`default_nettype none

module tb_tms34020_verified_leaves;

    import tms34020_pkg::*;

    logic clk;
    logic reset;

    logic [15:0] decode_word;
    logic decode_valid;
    tms34020_opcode_id_t decode_id;
    logic [2:0] decode_length;

    logic [31:0] add_destination;
    logic [31:0] add_immediate;
    logic [31:0] add_result;
    logic add_n;
    logic add_c;
    logic add_z;
    logic add_v;

    logic [31:0] pixel;
    logic [5:0] pixel_size;
    logic [31:0] pixel_result;
    logic pixel_valid;
    logic [3:0] pixel_states;

    logic [4:0] compare_constant;
    logic [31:0] compare_result;
    logic compare_n;
    logic compare_c;
    logic compare_z;
    logic compare_v;

    logic [31:0] rmo_source;
    logic [31:0] rmo_result;
    logic rmo_z;

    logic [15:0] pixel_size_register;
    logic [15:0] pixel_size_value;
    logic pixel_size_exchange;
    logic [31:0] pixel_size_register_result;
    logic pixel_size_write_enable;
    logic [15:0] pixel_size_write_data;

    logic register_write_enable;
    logic register_write_file;
    logic [3:0] register_write_index;
    logic [31:0] register_write_data;
    logic register_read0_file;
    logic [3:0] register_read0_index;
    logic [31:0] register_read0_data;
    logic register_read1_file;
    logic [3:0] register_read1_index;
    logic [31:0] register_read1_data;
    logic [31:0] sp;

    tms34020_decode decode_dut (
        .first_word_i(decode_word),
        .valid_o(decode_valid),
        .opcode_id_o(decode_id),
        .length_words_o(decode_length)
    );

    tms34020_addxyi addxyi_dut (
        .destination_i(add_destination),
        .immediate_i(add_immediate),
        .result_o(add_result),
        .status_n_o(add_n),
        .status_c_o(add_c),
        .status_z_o(add_z),
        .status_v_o(add_v)
    );

    tms34020_pixel_replicate pixel_dut (
        .pixel_i(pixel),
        .pixel_size_i(pixel_size),
        .result_o(pixel_result),
        .valid_o(pixel_valid),
        .machine_states_o(pixel_states)
    );

    tms34020_cmpk cmpk_dut (
        .destination_i(add_destination),
        .encoded_constant_i(compare_constant),
        .compare_result_o(compare_result),
        .status_n_o(compare_n),
        .status_c_o(compare_c),
        .status_z_o(compare_z),
        .status_v_o(compare_v)
    );

    tms34020_rmo rmo_dut (
        .source_i(rmo_source),
        .result_o(rmo_result),
        .status_z_o(rmo_z)
    );

    tms34020_pixel_size_ops pixel_size_ops_dut (
        .register_low_i(pixel_size_register),
        .psize_i(pixel_size_value),
        .exchange_i(pixel_size_exchange),
        .register_result_o(pixel_size_register_result),
        .psize_write_enable_o(pixel_size_write_enable),
        .psize_write_data_o(pixel_size_write_data)
    );

    tms34020_regfile regfile_dut (
        .clk_i(clk),
        .reset_i(reset),
        .write_enable_i(register_write_enable),
        .write_file_i(register_write_file),
        .write_index_i(register_write_index),
        .write_data_i(register_write_data),
        .read0_file_i(register_read0_file),
        .read0_index_i(register_read0_index),
        .read0_data_o(register_read0_data),
        .read1_file_i(register_read1_file),
        .read1_index_i(register_read1_index),
        .read1_data_o(register_read1_data),
        .sp_o(sp)
    );

    always #5 clk = ~clk;

    task automatic check_condition(input logic condition, input string message);
        if (!condition) begin
            $display("FAIL: %s", message);
            $fatal(1);
        end
    endtask

    task automatic check_decode(
        input logic [15:0] first_word,
        input tms34020_opcode_id_t expected_id,
        input logic [2:0] expected_length,
        input string message
    );
        decode_word = first_word;
        #1;
        check_condition(
            decode_valid &&
            decode_id == expected_id &&
            decode_length == expected_length,
            message
        );
    endtask

    task automatic check_pixel_replicate(
        input logic [5:0] size,
        input logic [31:0] expected_result,
        input logic [3:0] expected_states,
        input string message
    );
        pixel_size = size;
        #1;
        check_condition(
            pixel_valid &&
            pixel_result == expected_result &&
            pixel_states == expected_states,
            message
        );
    endtask

    task automatic write_register(
        input logic register_file,
        input logic [3:0] register_index_value,
        input logic [31:0] register_value
    );
        register_write_file = register_file;
        register_write_index = register_index_value;
        register_write_data = register_value;
        register_write_enable = 1'b1;
        @(posedge clk);
        #1;
        register_write_enable = 1'b0;
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        decode_word = 16'd0;
        add_destination = 32'd0;
        add_immediate = 32'd0;
        pixel = 32'd0;
        pixel_size = 6'd0;
        compare_constant = 5'd0;
        rmo_source = 32'd0;
        pixel_size_register = 16'd0;
        pixel_size_value = 16'd0;
        pixel_size_exchange = 1'b0;
        register_write_enable = 1'b0;
        register_write_file = 1'b0;
        register_write_index = 4'd0;
        register_write_data = 32'd0;
        register_read0_file = 1'b0;
        register_read0_index = 4'd0;
        register_read1_file = 1'b1;
        register_read1_index = 4'd0;

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;

        check_condition(TMS34020_DATA_WIDTH == 32,
                        "architectural data width constant");
        check_condition(TMS34020_WORD_BITS == 16,
                        "instruction word width constant");
        check_condition(TMS34020_ST_N_BIT == 31 &&
                        TMS34020_ST_C_BIT == 30 &&
                        TMS34020_ST_Z_BIT == 29 &&
                        TMS34020_ST_V_BIT == 28,
                        "status bit positions");
        check_condition(TMS34020_ST_RESET == 32'h0000_0010,
                        "status reset constant");

        check_decode(16'h0040, TMS20_OP_IDLE, 3'd1, "IDLE exact decode");
        check_decode(16'h0080, TMS20_OP_MWAIT, 3'd1, "MWAIT exact decode");
        check_decode(16'h0300, TMS20_OP_NOP, 3'd1, "NOP exact decode");
        check_decode(16'h0273, TMS20_OP_SETCDP, 3'd1,
                     "SETCDP exact decode");
        check_decode(16'h02FB, TMS20_OP_SETCMP, 3'd1,
                     "SETCMP exact decode");
        check_decode(16'h0251, TMS20_OP_SETCSP, 3'd1,
                     "SETCSP exact decode");
        check_decode(16'h080F, TMS20_OP_TRAPL, 3'd2,
                     "TRAPL consumes extension word");
        check_decode(16'h0A00, TMS20_OP_VLCOL, 3'd1, "VLCOL exact decode");
        check_decode(16'h00F3, TMS20_OP_BLMOVE, 3'd1,
                     "BLMOVE masked decode");
        check_decode(16'h0C1E, TMS20_OP_ADDXYI, 3'd3,
                     "ADDXYI masked decode");
        check_decode(16'h029E, TMS20_OP_RPIX, 3'd1, "RPIX masked decode");
        check_decode(16'h37FF, TMS20_OP_CMPK, 3'd1, "CMPK masked decode");
        check_decode(16'h02BF, TMS20_OP_EXGPS, 3'd1,
                     "EXGPS masked decode");
        check_decode(16'h02DF, TMS20_OP_GETPS, 3'd1,
                     "GETPS masked decode");
        check_decode(16'h7BFF, TMS20_OP_RMO, 3'd1, "RMO masked decode");

        decode_word = 16'h080E;
        #1;
        check_condition(!decode_valid && decode_id == TMS20_OP_UNCLASSIFIED,
               "nearby unclassified word must not alias TRAPL");

        add_destination = 32'h0001_0001;
        add_immediate = 32'hFFFF_FFFF;
        #1;
        check_condition(add_result == 32'h0000_0000,
               "ADDXYI independent half addition");
        check_condition({add_n, add_c, add_z, add_v} == 4'b1010,
               "ADDXYI TI-defined NCZV");

        add_destination = 32'h0002_0001;
        add_immediate = 32'h7FFF_7FFF;
        #1;
        check_condition(add_result == 32'h8001_8000, "ADDXYI sign cases");
        check_condition({add_n, add_c, add_z, add_v} == 4'b0101,
               "ADDXYI sign-derived flags");

        add_destination = 32'd0;
        compare_constant = 5'd0;
        #1;
        check_condition(compare_result == 32'hFFFF_FFE0,
                        "CMPK encoded zero means 32");
        check_condition({compare_n, compare_c, compare_z, compare_v} ==
                        4'b1100,
                        "CMPK borrow flags");

        add_destination = 32'h8000_0000;
        compare_constant = 5'd1;
        #1;
        check_condition(compare_result == 32'h7FFF_FFFF,
                        "CMPK subtraction result");
        check_condition({compare_n, compare_c, compare_z, compare_v} ==
                        4'b0001,
                        "CMPK signed overflow");

        rmo_source = 32'd0;
        #1;
        check_condition(rmo_z && rmo_result == 32'd0, "RMO zero source");
        rmo_source = 32'h8000_0000;
        #1;
        check_condition(!rmo_z && rmo_result == 32'd31, "RMO bit 31");
        rmo_source = 32'h0800_0010;
        #1;
        check_condition(!rmo_z && rmo_result == 32'd4, "RMO rightmost bit");

        pixel_size_register = 16'h0001;
        pixel_size_value = 16'd8;
        pixel_size_exchange = 1'b0;
        #1;
        check_condition(
            pixel_size_register_result == 32'd8 &&
            !pixel_size_write_enable &&
            pixel_size_write_data == 16'd0,
            "GETPS data path"
        );
        pixel_size_exchange = 1'b1;
        #1;
        check_condition(
            pixel_size_register_result == 32'd8 &&
            pixel_size_write_enable &&
            pixel_size_write_data == 16'd1,
            "EXGPS exchange data path"
        );

        pixel = 32'h89AB_CDEF;
        check_pixel_replicate(6'd1, 32'hFFFF_FFFF, 4'd8, "RPIX size 1");
        check_pixel_replicate(6'd2, 32'hFFFF_FFFF, 4'd7, "RPIX size 2");
        check_pixel_replicate(6'd4, 32'hFFFF_FFFF, 4'd6, "RPIX size 4");
        check_pixel_replicate(6'd8, 32'hEFEF_EFEF, 4'd5, "RPIX size 8");
        check_pixel_replicate(6'd16, 32'hCDEF_CDEF, 4'd4, "RPIX size 16");
        check_pixel_replicate(6'd32, 32'h89AB_CDEF, 4'd2, "RPIX size 32");

        pixel_size = 6'd3;
        #1;
        check_condition(!pixel_valid && pixel_states == 4'd0,
               "RPIX rejects reserved size");

        write_register(1'b0, 4'd2, 32'h1234_5678);
        register_read0_file = 1'b0;
        register_read0_index = 4'd2;
        #1;
        check_condition(register_read0_data == 32'h1234_5678, "A2 write/read");

        write_register(1'b1, 4'd2, 32'hCAFE_BABE);
        register_read1_file = 1'b1;
        register_read1_index = 4'd2;
        #1;
        check_condition(register_read1_data == 32'hCAFE_BABE, "B2 write/read");
        check_condition(register_read0_data == 32'h1234_5678,
               "A/B physical files remain distinct");

        write_register(1'b0, 4'd15, 32'h1020_3040);
        register_read0_file = 1'b0;
        register_read0_index = 4'd15;
        register_read1_file = 1'b1;
        register_read1_index = 4'd15;
        #1;
        check_condition(register_read0_data == 32'h1020_3040,
               "A15 reads shared SP");
        check_condition(register_read1_data == 32'h1020_3040,
               "B15 reads shared SP");
        check_condition(sp == 32'h1020_3040, "SP output");

        $display("PASS: tms34020 verified leaf RTL");
        $finish;
    end

endmodule

`default_nettype wire
