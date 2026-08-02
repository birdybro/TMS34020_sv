`default_nettype none

// Semantic formatter for the five documented CMOVCM/CMOVMC memory-sequence
// packets.  This leaf deliberately does not perform the physical page-mode,
// wait, fault, retry, or turnaround handshake; it exposes the architectural
// sequence parameters that a later local-bus sequencer must retire atomically.
module tms34020_coprocessor_memory_transfer (
    input  logic [15:0] first_word_i,
    input  logic [15:0] extension_word1_i,
    input  logic [15:0] extension_word2_i,
    input  logic        first_extension_aligned_i,
    input  logic [31:0] pointer_value_i,
    input  logic [4:0]  register_count_value_i,
    output logic        supported_o,
    output logic        legal_o,
    output logic        coprocessor_to_memory_o,
    output logic        predecrement_o,
    output logic        register_count_mode_o,
    output logic [2:0]  instruction_length_words_o,
    output logic        pointer_file_b_o,
    output logic [3:0]  pointer_index_o,
    output logic        count_file_b_o,
    output logic [3:0]  count_index_o,
    output logic [5:0]  transfer_count_o,
    output logic [2:0]  coprocessor_id_o,
    output logic [20:0] command_o,
    output logic        size_64_o,
    output logic [31:0] lad_command_o,
    output logic        special_function_o,
    output logic [3:0]  bus_status_o,
    output logic        word_select_16_o,
    output logic [31:0] first_address_o,
    output logic [31:0] final_pointer_o,
    output logic        command_reissue_after_page_break_o,
    output logic        write_turnaround_spacer_required_o,
    output logic [5:0]  visible_states_o
);

    logic memory_to_coprocessor_post_constant;
    logic coprocessor_to_memory_post_constant;
    logic coprocessor_to_memory_pre_constant;
    logic memory_to_coprocessor_post_register;
    logic memory_to_coprocessor_pre_constant;
    logic constant_count_mode;
    logic [4:0] encoded_count;
    logic [31:0] pointer_delta;

    always_comb begin
        memory_to_coprocessor_post_constant =
            (first_word_i & 16'hFFE0) == 16'h0680;
        coprocessor_to_memory_post_constant =
            (first_word_i & 16'hFFE0) == 16'h06A0;
        coprocessor_to_memory_pre_constant =
            (first_word_i & 16'hFFE0) == 16'h06C0;
        memory_to_coprocessor_post_register =
            (first_word_i & 16'hFFE0) == 16'h06E0;
        memory_to_coprocessor_pre_constant =
            (first_word_i & 16'hFFE0) == 16'h0820;

        supported_o =
            memory_to_coprocessor_post_constant ||
            coprocessor_to_memory_post_constant ||
            coprocessor_to_memory_pre_constant ||
            memory_to_coprocessor_post_register ||
            memory_to_coprocessor_pre_constant;
        coprocessor_to_memory_o =
            coprocessor_to_memory_post_constant ||
            coprocessor_to_memory_pre_constant;
        predecrement_o =
            coprocessor_to_memory_pre_constant ||
            memory_to_coprocessor_pre_constant;
        register_count_mode_o = memory_to_coprocessor_post_register;
        constant_count_mode = supported_o && !register_count_mode_o;
        size_64_o = extension_word1_i[7];

        encoded_count = 5'd0;
        if (register_count_mode_o) begin
            encoded_count = register_count_value_i;
        end else if (coprocessor_to_memory_o) begin
            encoded_count = extension_word1_i[4:0];
        end else begin
            encoded_count = first_word_i[4:0];
        end
        transfer_count_o =
            encoded_count == 5'd0 ? 6'd32 : {1'b0, encoded_count};

        legal_o = supported_o && extension_word1_i[6:5] == 2'd0 &&
            !(constant_count_mode && size_64_o && encoded_count[0]);
        instruction_length_words_o = supported_o ? 3'd3 : 3'd0;

        pointer_file_b_o = extension_word1_i[4];
        pointer_index_o = extension_word1_i[3:0];
        if (coprocessor_to_memory_o) begin
            pointer_file_b_o = first_word_i[4];
            pointer_index_o = first_word_i[3:0];
        end
        count_file_b_o = first_word_i[4];
        count_index_o = first_word_i[3:0];

        coprocessor_id_o = extension_word2_i[15:13];
        command_o = {
            extension_word2_i[12:0], extension_word1_i[15:8]
        };
        lad_command_o = {
            coprocessor_id_o, command_o, size_64_o, 7'd0
        };
        special_function_o = legal_o;
        bus_status_o = 4'd0;
        word_select_16_o = 1'b0;

        pointer_delta = {21'd0, transfer_count_o, 5'd0};
        first_address_o = predecrement_o
            ? pointer_value_i - 32'd32
            : pointer_value_i;
        final_pointer_o = predecrement_o
            ? pointer_value_i - pointer_delta
            : pointer_value_i + pointer_delta;

        // Chapter 10 requires only the next address/status after a page break.
        command_reissue_after_page_break_o = 1'b0;
        write_turnaround_spacer_required_o =
            legal_o && coprocessor_to_memory_o;
        visible_states_o = 6'd0;
        if (legal_o) begin
            visible_states_o = transfer_count_o +
                (first_extension_aligned_i ? 6'd4 : 6'd5);
        end
    end

endmodule

`default_nettype wire
