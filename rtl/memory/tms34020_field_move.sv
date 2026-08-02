`default_nettype none

module tms34020_field_move (
    input  logic [4:0]  field_size_encoded_i,
    input  logic [4:0]  source_bit_offset_i,
    input  logic [4:0]  destination_bit_offset_i,
    input  logic [31:0] source_word0_i,
    input  logic [31:0] source_word1_i,
    input  logic [31:0] destination_word0_i,
    input  logic [31:0] destination_word1_i,
    output logic [5:0]  field_size_o,
    output logic [2:0]  source_alignment_case_o,
    output logic [2:0]  destination_alignment_case_o,
    output logic        reads_source_word1_o,
    output logic        writes_destination_word1_o,
    output logic [2:0]  visible_states_o,
    output logic [2:0]  hidden_write_states_o,
    output logic [31:0] field_value_o,
    output logic [31:0] destination_word0_o,
    output logic [31:0] destination_word1_o
);

    logic [6:0] source_end;
    logic [6:0] destination_end;
    logic [31:0] field_mask;
    logic [63:0] source_window;
    logic [63:0] destination_window;
    logic [63:0] positioned_mask;
    logic [63:0] new_destination_window;
    logic [5:0] source_offset_extended;

    function automatic logic [2:0] alignment_case(
        input logic [2:0] byte_bit_offset,
        input logic [6:0] field_end
    );
        logic crosses_word;
        logic start_byte_aligned;
        logic end_byte_aligned;
        begin
            crosses_word = field_end > 7'd32;
            start_byte_aligned = byte_bit_offset == 3'd0;
            end_byte_aligned = field_end[2:0] == 3'd0;
            if (!crosses_word) begin
                alignment_case =
                    (start_byte_aligned && end_byte_aligned) ? 3'd1 : 3'd2;
            end else if (start_byte_aligned && end_byte_aligned) begin
                alignment_case = 3'd3;
            end else if (start_byte_aligned || end_byte_aligned) begin
                alignment_case = 3'd4;
            end else begin
                alignment_case = 3'd5;
            end
        end
    endfunction

    always_comb begin
        field_size_o = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size_o = 6'd32;
        end
        source_end =
            {2'd0, source_bit_offset_i} + {1'd0, field_size_o};
        destination_end =
            {2'd0, destination_bit_offset_i} + {1'd0, field_size_o};
        source_alignment_case_o =
            alignment_case(source_bit_offset_i[2:0], source_end);
        destination_alignment_case_o =
            alignment_case(destination_bit_offset_i[2:0], destination_end);
        reads_source_word1_o = source_end > 7'd32;
        writes_destination_word1_o = destination_end > 7'd32;
        visible_states_o =
            (source_alignment_case_o <= 3'd2) ? 3'd3 : 3'd4;
        unique case (destination_alignment_case_o)
            3'd1: hidden_write_states_o = 3'd1;
            3'd2: hidden_write_states_o = 3'd2;
            3'd3: hidden_write_states_o = 3'd2;
            3'd4: hidden_write_states_o = 3'd3;
            default: hidden_write_states_o = 3'd4;
        endcase

        field_mask = 32'hFFFF_FFFF;
        if (field_size_o != 6'd32) begin
            field_mask = (32'd1 << field_size_o) - 32'd1;
        end
        source_window = {source_word1_i, source_word0_i};
        source_offset_extended = {1'b0, source_bit_offset_i};
        field_value_o =
            source_window[source_offset_extended +: 32] & field_mask;

        destination_window = {destination_word1_i, destination_word0_i};
        positioned_mask =
            {32'd0, field_mask} << destination_bit_offset_i;
        new_destination_window =
            (destination_window & ~positioned_mask) |
            (({32'd0, field_value_o} << destination_bit_offset_i) &
             positioned_mask);
        destination_word0_o = new_destination_window[31:0];
        destination_word1_o = new_destination_window[63:32];
    end

endmodule

`default_nettype wire
