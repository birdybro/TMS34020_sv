`timescale 1ns/1ps
`default_nettype none

module tms34020_leaf_synth_top (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [15:0] first_word_i,
    input  logic [31:0] operand_i,
    input  logic [31:0] immediate_i,
    input  logic [5:0]  pixel_size_i,
    input  logic        write_enable_i,
    input  logic        write_file_i,
    input  logic [3:0]  write_index_i,
    output logic [31:0] result_digest_o
);

    import tms34020_pkg::*;

    tms34020_opcode_id_t decoded_id;
    logic decode_valid;
    logic [2:0] decode_length;
    logic [31:0] add_result;
    logic [3:0] add_nczv;
    logic [31:0] pixel_result;
    logic pixel_valid;
    logic [3:0] pixel_states;
    logic [31:0] register_data;
    logic [31:0] sp;
    logic register_read_file;
    logic [3:0] register_read_index;
    logic [31:0] second_register_data;

    assign register_read_file = first_word_i[4];
    assign register_read_index = first_word_i[3:0];
    assign result_digest_o =
        add_result ^
        pixel_result ^
        register_data ^
        second_register_data ^
        sp ^
        {15'd0, add_nczv, decode_valid, decoded_id, decode_length,
         pixel_valid, pixel_states};

    tms34020_decode decode (
        .first_word_i(first_word_i),
        .valid_o(decode_valid),
        .opcode_id_o(decoded_id),
        .length_words_o(decode_length)
    );

    tms34020_addxyi addxyi (
        .destination_i(operand_i),
        .immediate_i(immediate_i),
        .result_o(add_result),
        .status_n_o(add_nczv[3]),
        .status_c_o(add_nczv[2]),
        .status_z_o(add_nczv[1]),
        .status_v_o(add_nczv[0])
    );

    tms34020_pixel_replicate pixel_replicate (
        .pixel_i(operand_i),
        .pixel_size_i(pixel_size_i),
        .result_o(pixel_result),
        .valid_o(pixel_valid),
        .machine_states_o(pixel_states)
    );

    tms34020_regfile regfile (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .write_enable_i(write_enable_i),
        .write_file_i(write_file_i),
        .write_index_i(write_index_i),
        .write_data_i(immediate_i),
        .read0_file_i(register_read_file),
        .read0_index_i(register_read_index),
        .read0_data_o(register_data),
        .read1_file_i(~register_read_file),
        .read1_index_i(register_read_index),
        .read1_data_o(second_register_data),
        .sp_o(sp)
    );

endmodule

`default_nettype wire
