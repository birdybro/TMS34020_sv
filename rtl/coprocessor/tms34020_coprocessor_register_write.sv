`default_nettype none

module tms34020_coprocessor_register_write (
    input  logic [15:0] first_word_i,
    input  logic [15:0] extension_word1_i,
    input  logic [15:0] extension_word2_i,
    input  logic        first_extension_aligned_i,
    input  logic [31:0] source1_value_i,
    input  logic [31:0] source2_value_i,
    output logic        supported_o,
    output logic        legal_o,
    output logic        two_registers_o,
    output logic [2:0]  instruction_length_words_o,
    output logic        source1_file_b_o,
    output logic [3:0]  source1_index_o,
    output logic        source2_file_b_o,
    output logic [3:0]  source2_index_o,
    output logic [2:0]  coprocessor_id_o,
    output logic [20:0] command_o,
    output logic        size_64_o,
    output logic [31:0] lad_command_o,
    output logic [31:0] lad_second_reissue_o,
    output logic        special_function_o,
    output logic [3:0]  bus_status_o,
    output logic        word_select_16_o,
    output logic [31:0] data_word0_o,
    output logic [31:0] data_word1_o,
    output logic [1:0]  data_word_count_o,
    output logic        second_reissue_if_no_page_o,
    output logic [2:0]  visible_states_o,
    output logic        hidden_transfer_state_o
);

    logic one_register;

    always_comb begin
        one_register =
            (first_word_i & 16'hFFE0) == 16'h0620;
        two_registers_o =
            (first_word_i & 16'hFFE0) == 16'h0640;
        supported_o = one_register || two_registers_o;
        legal_o = supported_o &&
            ((one_register && extension_word1_i[7:0] == 8'd0) ||
             (two_registers_o && extension_word1_i[6:5] == 2'd0));
        instruction_length_words_o = supported_o ? 3'd3 : 3'd0;
        source1_file_b_o = first_word_i[4];
        source1_index_o = first_word_i[3:0];
        source2_file_b_o = extension_word1_i[4];
        source2_index_o = extension_word1_i[3:0];
        coprocessor_id_o = extension_word2_i[15:13];
        command_o = {
            extension_word2_i[12:0], extension_word1_i[15:8]
        };
        size_64_o = two_registers_o && extension_word1_i[7];
        lad_command_o = {
            coprocessor_id_o, command_o, size_64_o, 7'd0
        };
        lad_second_reissue_o = lad_command_o | 32'h0000_0040;
        special_function_o = legal_o;
        bus_status_o = 4'd0;
        word_select_16_o = 1'b0;
        data_word0_o = source1_value_i;
        data_word1_o = source2_value_i;
        data_word_count_o =
            legal_o ? (two_registers_o ? 2'd2 : 2'd1) : 2'd0;
        second_reissue_if_no_page_o = legal_o && two_registers_o;
        visible_states_o = 3'd0;
        if (legal_o) begin
            if (two_registers_o) begin
                visible_states_o =
                    first_extension_aligned_i ? 3'd3 : 3'd4;
            end else begin
                visible_states_o =
                    first_extension_aligned_i ? 3'd2 : 3'd3;
            end
        end
        hidden_transfer_state_o = legal_o;
    end

endmodule

`default_nettype wire
