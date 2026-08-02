`default_nettype none

module tms34020_absolute_address (
    input  logic [15:0] address_low_i,
    input  logic [15:0] address_high_i,
    output logic [31:0] bit_address_o
);

    always_comb begin
        bit_address_o = {address_high_i, address_low_i};
    end

endmodule

`default_nettype wire
