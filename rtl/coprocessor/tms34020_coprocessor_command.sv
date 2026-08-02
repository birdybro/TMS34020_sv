`default_nettype none

module tms34020_coprocessor_command (
    input  logic [15:0] first_word_i,
    input  logic [15:0] extension_word1_i,
    input  logic [15:0] extension_word2_i,
    input  logic        first_extension_aligned_i,
    output logic        supported_o,
    output logic        legal_o,
    output logic        long_form_o,
    output logic [2:0]  instruction_length_words_o,
    output logic [2:0]  coprocessor_id_o,
    output logic [20:0] command_o,
    output logic        size_64_o,
    output logic [31:0] lad_command_o,
    output logic        special_function_o,
    output logic [3:0]  bus_status_o,
    output logic        parameter_index_o,
    output logic        word_select_16_o,
    output logic [1:0]  visible_states_o,
    output logic        hidden_command_state_o
);

    logic short_form;

    always_comb begin
        long_form_o = first_word_i == 16'h0600;
        short_form = (first_word_i & 16'hFF80) == 16'hD800;
        supported_o = long_form_o || short_form;
        legal_o = supported_o &&
            (!long_form_o || extension_word1_i[6:0] == 7'd0);
        instruction_length_words_o = 3'd0;
        coprocessor_id_o = 3'd0;
        command_o = 21'd0;
        size_64_o = 1'b0;
        visible_states_o = 2'd0;
        if (long_form_o) begin
            instruction_length_words_o = 3'd3;
            coprocessor_id_o = extension_word2_i[15:13];
            command_o = {
                extension_word2_i[12:0], extension_word1_i[15:8]
            };
            size_64_o = extension_word1_i[7];
            visible_states_o =
                first_extension_aligned_i ? 2'd2 : 2'd3;
        end else if (short_form) begin
            instruction_length_words_o = 3'd2;
            coprocessor_id_o = extension_word1_i[15:13];
            command_o = {
                extension_word1_i[12:0], 2'b00, first_word_i[6:1]
            };
            size_64_o = first_word_i[0];
            visible_states_o = 2'd2;
        end
        lad_command_o = {
            coprocessor_id_o, command_o, size_64_o, 7'd0
        };
        special_function_o = legal_o;
        bus_status_o = 4'd0;
        parameter_index_o = 1'b0;
        word_select_16_o = 1'b0;
        hidden_command_state_o = legal_o;
    end

endmodule

`default_nettype wire
