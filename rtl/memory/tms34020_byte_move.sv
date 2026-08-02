`default_nettype none

module tms34020_byte_move (
    input  logic [1:0]  address_mode_i,
    input  logic        first_extension_aligned_i,
    input  logic [4:0]  source_bit_offset_i,
    input  logic [4:0]  destination_bit_offset_i,
    input  logic [31:0] source_word0_i,
    input  logic [31:0] source_word1_i,
    input  logic [31:0] destination_word0_i,
    input  logic [31:0] destination_word1_i,
    output logic        mode_valid_o,
    output logic [2:0]  source_case_o,
    output logic [2:0]  destination_case_o,
    output logic        reads_source_word1_o,
    output logic        writes_destination_word1_o,
    output logic [2:0]  timing_column_o,
    output logic        offset_case_e_override_o,
    output logic [3:0]  visible_states_o,
    output logic [2:0]  hidden_write_states_o,
    output logic [31:0] byte_value_o,
    output logic [31:0] destination_word0_o,
    output logic [31:0] destination_word1_o
);

    logic [5:0] fixed_field_size;
    logic [2:0] indirect_visible_states;
    logic [2:0] geometric_hidden_states;

    tms34020_field_move fixed_byte_move (
        .field_size_encoded_i(5'd8),
        .source_bit_offset_i(source_bit_offset_i),
        .destination_bit_offset_i(destination_bit_offset_i),
        .source_word0_i(source_word0_i),
        .source_word1_i(source_word1_i),
        .destination_word0_i(destination_word0_i),
        .destination_word1_i(destination_word1_i),
        .field_size_o(fixed_field_size),
        .source_alignment_case_o(source_case_o),
        .destination_alignment_case_o(destination_case_o),
        .reads_source_word1_o(reads_source_word1_o),
        .writes_destination_word1_o(writes_destination_word1_o),
        .visible_states_o(indirect_visible_states),
        .hidden_write_states_o(geometric_hidden_states),
        .field_value_o(byte_value_o),
        .destination_word0_o(destination_word0_o),
        .destination_word1_o(destination_word1_o)
    );

    always_comb begin
        mode_valid_o =
            address_mode_i != 2'd3 &&
            fixed_field_size == 6'd8 &&
            (source_case_o == 3'd1 || source_case_o == 3'd2 ||
             source_case_o == 3'd5) &&
            (destination_case_o == 3'd1 || destination_case_o == 3'd2 ||
             destination_case_o == 3'd5);
        if (destination_case_o == 3'd1) begin
            timing_column_o = source_case_o == 3'd5 ? 3'd1 : 3'd0;
        end else if (destination_case_o == 3'd2) begin
            timing_column_o = source_case_o == 3'd5 ? 3'd3 : 3'd2;
        end else begin
            timing_column_o = source_case_o == 3'd5 ? 3'd5 : 3'd4;
        end
        offset_case_e_override_o =
            address_mode_i == 2'd1 && timing_column_o == 3'd4;
        hidden_write_states_o = geometric_hidden_states;
        if (offset_case_e_override_o) begin
            hidden_write_states_o = 3'd2;
        end
        unique case (address_mode_i)
            2'd0: visible_states_o =
                {1'b0, indirect_visible_states};
            2'd1: visible_states_o =
                {1'b0, indirect_visible_states} + 4'd2;
            2'd2: visible_states_o =
                {1'b0, indirect_visible_states} +
                (first_extension_aligned_i ? 4'd2 : 4'd4);
            default: begin
                timing_column_o = 3'd7;
                offset_case_e_override_o = 1'b0;
                visible_states_o = 4'd0;
                hidden_write_states_o = 3'd0;
            end
        endcase
    end

endmodule

`default_nettype wire
