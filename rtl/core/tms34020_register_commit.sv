`timescale 1ns/1ps
`default_nettype none

module tms34020_register_commit (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic        commit_i,
    input  logic [47:0] packet_words_i,
    input  logic [2:0]  packet_length_words_i,

    output logic        supported_o,
    output logic        commit_accepted_o,

    output logic        register_write_enable_o,
    output logic        register_write_file_o,
    output logic [3:0]  register_write_index_o,
    output logic [31:0] register_write_data_o,

    output logic        status_write_enable_o,
    output logic [31:0] status_write_data_o,
    output logic [31:0] status_write_mask_o,

    output logic [31:0] status_o,
    output logic [31:0] sp_o
);

    logic register_file;
    logic [3:0] source_index;
    logic [3:0] destination_index;
    logic [31:0] source_data;
    logic [31:0] destination_data;
    logic register_write_intent;
    logic [31:0] register_write_data;
    logic status_write_intent;
    logic [31:0] status_write_data;
    logic [31:0] status_write_mask;

    tms34020_regfile regfile (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .write_enable_i(register_write_enable_o),
        .write_file_i(register_write_file_o),
        .write_index_i(register_write_index_o),
        .write_data_i(register_write_data_o),
        .read0_file_i(register_file),
        .read0_index_i(source_index),
        .read0_data_o(source_data),
        .read1_file_i(register_file),
        .read1_index_i(destination_index),
        .read1_data_o(destination_data),
        .sp_o(sp_o)
    );

    tms34020_status status (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .write_enable_i(status_write_enable_o),
        .write_data_i(status_write_data_o),
        .write_mask_i(status_write_mask_o),
        .status_o(status_o)
    );

    tms34020_register_execute execute (
        .first_word_i(packet_words_i[15:0]),
        .packet_length_words_i(packet_length_words_i),
        .immediate_i(packet_words_i[47:16]),
        .source_i(source_data),
        .destination_i(destination_data),
        .status_i(status_o),
        .supported_o(supported_o),
        .register_file_o(register_file),
        .source_index_o(source_index),
        .destination_index_o(destination_index),
        .register_write_enable_o(register_write_intent),
        .register_write_data_o(register_write_data),
        .status_write_enable_o(status_write_intent),
        .status_write_data_o(status_write_data),
        .status_write_mask_o(status_write_mask)
    );

    always_comb begin
        commit_accepted_o = commit_i && supported_o;
        register_write_enable_o =
            commit_accepted_o && register_write_intent;
        register_write_file_o = register_file;
        register_write_index_o = destination_index;
        register_write_data_o = register_write_data;
        status_write_enable_o =
            commit_accepted_o && status_write_intent;
        status_write_data_o = status_write_data;
        status_write_mask_o = status_write_mask;
    end

endmodule

`default_nettype wire
