`timescale 1ns/1ps
`default_nettype none

module tms34020_register_commit #(
    parameter logic DEVICE_REVISION_SELECTED = 1'b0,
    parameter logic [31:0] DEVICE_REVISION_VALUE = 32'd0
) (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic        commit_i,
    input  logic [47:0] packet_words_i,
    input  logic [2:0]  packet_length_words_i,
    input  logic [31:0] sequential_next_pc_i,

    output logic        supported_o,
    output logic        commit_accepted_o,

    output logic        register_write_enable_o,
    output logic        register_write_file_o,
    output logic [3:0]  register_write_index_o,
    output logic [31:0] register_write_data_o,

    output logic        status_write_enable_o,
    output logic [31:0] status_write_data_o,
    output logic [31:0] status_write_mask_o,

    output logic        pc_redirect_enable_o,
    output logic [31:0] pc_redirect_bit_address_o,

    output logic [31:0] status_o,
    output logic [31:0] sp_o
);

    logic source_register_file;
    logic destination_register_file;
    logic [3:0] source_index;
    logic [3:0] destination_index;
    logic [31:0] source_data;
    logic [31:0] destination_data;
    logic register_execute_supported;
    logic register_execute_write_intent;
    logic [31:0] register_execute_write_data;
    logic status_write_intent;
    logic [31:0] status_write_data;
    logic [31:0] status_write_mask;
    logic pc_execute_supported;
    logic pc_register_write_intent;
    logic [31:0] pc_register_write_data;
    logic pc_redirect_intent;
    logic [31:0] pc_redirect_bit_address;

    tms34020_regfile regfile (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .write_enable_i(register_write_enable_o),
        .write_file_i(register_write_file_o),
        .write_index_i(register_write_index_o),
        .write_data_i(register_write_data_o),
        .read0_file_i(source_register_file),
        .read0_index_i(source_index),
        .read0_data_o(source_data),
        .read1_file_i(destination_register_file),
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

    tms34020_register_execute #(
        .DEVICE_REVISION_SELECTED(DEVICE_REVISION_SELECTED),
        .DEVICE_REVISION_VALUE(DEVICE_REVISION_VALUE)
    ) execute (
        .first_word_i(packet_words_i[15:0]),
        .packet_length_words_i(packet_length_words_i),
        .immediate_i(packet_words_i[47:16]),
        .source_i(source_data),
        .destination_i(destination_data),
        .status_i(status_o),
        .supported_o(register_execute_supported),
        .source_register_file_o(source_register_file),
        .destination_register_file_o(destination_register_file),
        .source_index_o(source_index),
        .destination_index_o(destination_index),
        .register_write_enable_o(register_execute_write_intent),
        .register_write_data_o(register_execute_write_data),
        .status_write_enable_o(status_write_intent),
        .status_write_data_o(status_write_data),
        .status_write_mask_o(status_write_mask)
    );

    tms34020_pc_execute pc_execute (
        .first_word_i(packet_words_i[15:0]),
        .packet_length_words_i(packet_length_words_i),
        .immediate_i(packet_words_i[47:16]),
        .sequential_next_pc_i(sequential_next_pc_i),
        .destination_i(destination_data),
        .status_i(status_o),
        .supported_o(pc_execute_supported),
        .register_write_enable_o(pc_register_write_intent),
        .register_write_data_o(pc_register_write_data),
        .redirect_enable_o(pc_redirect_intent),
        .redirect_bit_address_o(pc_redirect_bit_address)
    );

    always_comb begin
        supported_o =
            register_execute_supported || pc_execute_supported;
        commit_accepted_o = commit_i && supported_o;
        register_write_enable_o =
            commit_accepted_o &&
            (
                register_execute_write_intent ||
                pc_register_write_intent
            );
        register_write_file_o = destination_register_file;
        register_write_index_o = destination_index;
        register_write_data_o = register_execute_write_data;
        if (pc_execute_supported) begin
            register_write_data_o = pc_register_write_data;
        end
        status_write_enable_o =
            commit_accepted_o && status_write_intent;
        status_write_data_o = status_write_data;
        status_write_mask_o = status_write_mask;
        pc_redirect_enable_o =
            commit_accepted_o && pc_redirect_intent;
        pc_redirect_bit_address_o = pc_redirect_bit_address;
    end

`ifndef SYNTHESIS
    property p_execute_owners_are_mutually_exclusive;
        @(posedge clk_i) disable iff (reset_i)
            !(register_execute_supported && pc_execute_supported);
    endproperty

    property p_redirect_is_aligned_and_committed;
        @(posedge clk_i) disable iff (reset_i)
            pc_redirect_enable_o
            |-> commit_accepted_o &&
                pc_redirect_bit_address_o[3:0] == 4'd0;
    endproperty

    property p_rev_commit_uses_selected_identity;
        @(posedge clk_i) disable iff (reset_i)
            commit_accepted_o &&
            ((packet_words_i[15:0] & 16'hFFE0) == 16'h0020)
            |-> DEVICE_REVISION_SELECTED &&
                register_write_enable_o &&
                register_write_data_o == DEVICE_REVISION_VALUE &&
                !status_write_enable_o &&
                !pc_redirect_enable_o;
    endproperty

    assert property (p_execute_owners_are_mutually_exclusive);
    assert property (p_redirect_is_aligned_and_committed);
    assert property (p_rev_commit_uses_selected_identity);
`endif

endmodule

`default_nettype wire
