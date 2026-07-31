`timescale 1ns/1ps
`default_nettype none

module tms34020_decode (
    input  logic [15:0] first_word_i,
    output logic        valid_o,
    output tms34020_pkg::tms34020_opcode_id_t opcode_id_o,
    output logic [2:0]  length_words_o
);

    import tms34020_pkg::*;

    tms34020_decode_t decoded;

    always_comb begin
        decoded = tms34020_decode_word(first_word_i);
        valid_o = decoded.valid;
        opcode_id_o = decoded.opcode_id;
        length_words_o = decoded.length_words;
    end

endmodule

`default_nettype wire
