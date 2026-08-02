`default_nettype none

module tms34020_divider (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic        start_i,
    input  logic        signed_i,
    input  logic        pair_i,
    input  logic        modulo_i,
    input  logic [31:0] dividend_high_i,
    input  logic [31:0] dividend_low_i,
    input  logic [31:0] divisor_i,
    output logic        busy_o,
    output logic        done_o,
    output logic [31:0] quotient_o,
    output logic [31:0] remainder_o,
    output logic        overflow_o,
    output logic        n_o,
    output logic        z_o,
    output logic        v_o,
    output logic [5:0]  visible_states_o
);

    logic        signed_q;
    logic        pair_q;
    logic        modulo_q;
    logic        dividend_negative_q;
    logic        quotient_negative_q;
    logic [31:0] divisor_q;
    logic [31:0] remainder_q;
    logic [31:0] quotient_q;
    logic [5:0]  iteration_q;

    logic        dividend_negative_input;
    logic        divisor_negative_input;
    logic [63:0] signed_dividend_input;
    logic [63:0] dividend_magnitude_input;
    logic [31:0] divisor_magnitude_input;
    logic [32:0] shifted_remainder;
    logic        subtract_divisor;
    logic [31:0] remainder_step;
    logic [31:0] quotient_step;
    logic [31:0] signed_quotient_step;
    logic [31:0] signed_remainder_step;
    logic        signed_range_overflow;

    always_comb begin
        dividend_negative_input = signed_i && (
            pair_i ? dividend_high_i[31] : dividend_low_i[31]
        );
        divisor_negative_input = signed_i && divisor_i[31];
        signed_dividend_input = pair_i
            ? {dividend_high_i, dividend_low_i}
            : {{32{dividend_low_i[31]}}, dividend_low_i};
        dividend_magnitude_input = dividend_negative_input
            ? (~signed_dividend_input + 64'd1)
            : signed_dividend_input;
        divisor_magnitude_input = divisor_negative_input
            ? (~divisor_i + 32'd1)
            : divisor_i;

        shifted_remainder = {remainder_q[31:0], quotient_q[31]};
        subtract_divisor = shifted_remainder >= {1'b0, divisor_q};
        remainder_step = subtract_divisor
            ? shifted_remainder[31:0] - divisor_q
            : shifted_remainder[31:0];
        quotient_step = {quotient_q[30:0], subtract_divisor};
        signed_quotient_step = quotient_negative_q
            ? (~quotient_step + 32'd1)
            : quotient_step;
        signed_remainder_step = dividend_negative_q
            ? (~remainder_step + 32'd1)
            : remainder_step;
        signed_range_overflow = signed_q && (
            quotient_negative_q
                ? quotient_step > 32'h8000_0000
                : quotient_step >= 32'h8000_0000
        );
    end

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            signed_q <= 1'b0;
            pair_q <= 1'b0;
            modulo_q <= 1'b0;
            dividend_negative_q <= 1'b0;
            quotient_negative_q <= 1'b0;
            divisor_q <= 32'd0;
            remainder_q <= 32'd0;
            quotient_q <= 32'd0;
            iteration_q <= 6'd0;
            busy_o <= 1'b0;
            done_o <= 1'b0;
            quotient_o <= 32'd0;
            remainder_o <= 32'd0;
            overflow_o <= 1'b0;
            n_o <= 1'b0;
            z_o <= 1'b0;
            v_o <= 1'b0;
            visible_states_o <= 6'd0;
        end else begin
            done_o <= 1'b0;
            if (start_i && !busy_o) begin
                signed_q <= signed_i;
                pair_q <= pair_i;
                modulo_q <= modulo_i;
                dividend_negative_q <= dividend_negative_input;
                quotient_negative_q <=
                    dividend_negative_input ^ divisor_negative_input;
                divisor_q <= divisor_magnitude_input;
                remainder_q <= dividend_magnitude_input[63:32];
                quotient_q <= dividend_magnitude_input[31:0];
                iteration_q <= 6'd0;
                quotient_o <= 32'd0;
                remainder_o <= 32'd0;
                n_o <= 1'b0;
                z_o <= 1'b0;

                if ((divisor_magnitude_input == 32'd0) ||
                    (pair_i &&
                     (dividend_magnitude_input[63:32] >=
                      divisor_magnitude_input))) begin
                    busy_o <= 1'b0;
                    done_o <= 1'b1;
                    overflow_o <= 1'b1;
                    v_o <= 1'b1;
                    remainder_o <= modulo_i ? dividend_low_i : 32'd0;
                    visible_states_o <= modulo_i
                        ? 6'd3
                        : (signed_i
                            ? 6'd7
                            : (pair_i ? 6'd5 : 6'd7));
                end else begin
                    busy_o <= 1'b1;
                    overflow_o <= 1'b0;
                    v_o <= 1'b0;
                    visible_states_o <= 6'd0;
                end
            end else if (busy_o) begin
                remainder_q <= remainder_step;
                quotient_q <= quotient_step;
                if (iteration_q == 6'd31) begin
                    busy_o <= 1'b0;
                    done_o <= 1'b1;
                    overflow_o <= !modulo_q && signed_range_overflow;
                    v_o <= !modulo_q && signed_range_overflow;
                    quotient_o <= signed_q
                        ? signed_quotient_step
                        : quotient_step;
                    remainder_o <= signed_q
                        ? signed_remainder_step
                        : remainder_step;
                    n_o <= signed_q && (
                        modulo_q
                            ? (dividend_negative_q &&
                               (remainder_step != 32'd0))
                            : ((quotient_negative_q &&
                                (quotient_step != 32'd0)) ||
                               (signed_quotient_step == 32'h8000_0000))
                    );
                    z_o <= modulo_q
                        ? (remainder_step == 32'd0)
                        : (!signed_range_overflow &&
                           (quotient_step == 32'd0));
                    if (modulo_q) begin
                        visible_states_o <= signed_q
                            ? ((signed_remainder_step == 32'h8000_0000)
                                ? 6'd41 : 6'd40)
                            : 6'd35;
                    end else if (signed_q) begin
                        visible_states_o <=
                            (signed_quotient_step == 32'h8000_0000)
                                ? 6'd41
                                : (pair_q ? 6'd40 : 6'd39);
                    end else begin
                        visible_states_o <= 6'd37;
                    end
                end else begin
                    iteration_q <= iteration_q + 6'd1;
                end
            end
        end
    end

`ifndef SYNTHESIS
    property p_done_not_busy;
        @(posedge clk_i) disable iff (reset_i)
            done_o |-> !busy_o;
    endproperty

    property p_result_stable_while_busy;
        @(posedge clk_i) disable iff (reset_i)
            busy_o && $past(busy_o) |->
                $stable({quotient_o, remainder_o, overflow_o,
                         n_o, z_o, v_o, visible_states_o});
    endproperty

    property p_modulus_uses_single_destination;
        @(posedge clk_i) disable iff (reset_i)
            start_i && modulo_i |-> !pair_i;
    endproperty

    assert property (p_done_not_busy);
    assert property (p_result_stable_while_busy);
    assert property (p_modulus_uses_single_destination);
`endif

endmodule

`default_nettype wire
