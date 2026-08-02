`default_nettype none

module tms34020_byte_store (
    input  logic [1:0]  address_mode_i,
    input  logic        first_extension_aligned_i,
    input  logic [4:0]  destination_offset_i,
    input  logic [31:0] source_i,
    input  logic [31:0] destination_word0_i,
    input  logic [31:0] destination_word1_i,
    output logic        mode_valid_o,
    output logic [2:0]  destination_case_o,
    output logic [2:0]  visible_states_o,
    output logic [2:0]  hidden_states_o,
    output logic [31:0] destination_word0_o,
    output logic [31:0] destination_word1_o
);

    logic [5:0] fixed_field_size;
    logic       writes_word1;

    tms34020_field_store fixed_byte_store (
        .field_size_encoded_i(5'd8),
        .bit_offset_i(destination_offset_i),
        .source_i(source_i),
        .word0_i(destination_word0_i),
        .word1_i(destination_word1_i),
        .field_size_o(fixed_field_size),
        .alignment_case_o(destination_case_o),
        .hidden_write_states_o(hidden_states_o),
        .writes_word1_o(writes_word1),
        .word0_o(destination_word0_o),
        .word1_o(destination_word1_o)
    );

    always_comb begin
        mode_valid_o =
            address_mode_i != 2'd3 &&
            fixed_field_size == 6'd8 &&
            writes_word1 == (destination_offset_i > 5'd24);
        unique case (address_mode_i)
            2'd0: visible_states_o = 3'd1;
            2'd1: visible_states_o = 3'd3;
            2'd2: begin
                visible_states_o = first_extension_aligned_i
                    ? 3'd2 : 3'd3;
            end
            default: visible_states_o = 3'd0;
        endcase
    end

endmodule

`default_nettype wire
