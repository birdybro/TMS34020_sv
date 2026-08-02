`default_nettype none

module tms34020_multiplier (
    input  logic        signed_i,
    input  logic [4:0]  field_size_encoded_i,
    input  logic [31:0] source_i,
    input  logic [31:0] destination_i,
    output logic        legal_field_size_o,
    output logic [63:0] product_o,
    output logic        n_o,
    output logic        z_o,
    output logic [5:0]  visible_states_o
);

    logic [5:0] field_size;
    logic [4:0] sign_bit_index;
    logic [31:0] field_mask;
    logic [31:0] unsigned_multiplier;
    logic signed [31:0] signed_multiplier;
    logic signed [31:0] signed_multiplicand;
    logic signed [63:0] signed_product;
    logic [63:0] unsigned_product;

    always_comb begin
        field_size = {1'b0, field_size_encoded_i};
        if (field_size_encoded_i == 5'd0) begin
            field_size = 6'd32;
        end
        sign_bit_index = field_size[4:0] - 5'd1;
        legal_field_size_o = !field_size[0];

        field_mask = 32'hFFFF_FFFF;
        if (field_size != 6'd32) begin
            field_mask = 32'hFFFF_FFFF >> (6'd32 - field_size);
        end
        unsigned_multiplier = source_i & field_mask;
        signed_multiplier = $signed(unsigned_multiplier);
        if ((field_size != 6'd32) &&
            unsigned_multiplier[sign_bit_index]) begin
            signed_multiplier = $signed(
                unsigned_multiplier | ~field_mask
            );
        end
        signed_multiplicand = $signed(destination_i);
        signed_product = signed_multiplier * signed_multiplicand;
        unsigned_product = unsigned_multiplier * destination_i;

        product_o = signed_i ? signed_product : unsigned_product;
        n_o = signed_i && product_o[63];
        z_o = product_o == 64'd0;
        visible_states_o = 6'd5 + field_size[5:1];
        if (!signed_i && source_i[31]) begin
            visible_states_o = visible_states_o + 6'd1;
        end
    end

endmodule

`default_nettype wire
