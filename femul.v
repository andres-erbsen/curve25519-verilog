`default_nettype none

module femul(input wire clock, start,
             input wire [254:0] a_in, b_in,
             output reg done = 0,
             output wire [254:0] out);
    parameter W = 17; // hardware multiplier input word size
    parameter N = 15; // number of words used to represent one field element
    parameter C = 19; // pseudo-Mersenne coefficient
    parameter P = (255'b1<<(N*W)) - C; // 2^255 - 19
    parameter LOGC = 4;
    parameter LOGN = 4;

    function [2*W+LOGN+LOGC-1:0] mult19 (input [2*W+LOGN-1:0] a);
        assign mult19 = a + (a<<1) + (a<<4);
    endfunction

    reg [254:0] a = 0;
    reg [254:0] b = 0;
    reg [2*W-1:0] partialProduct [N-1:0];
    reg [2*W + LOGN + LOGC - 1:0] acc [N-1:0];
    reg [LOGN-1:0] multiply_step = N, accumulate_step = N;

    always @ (posedge clock) begin
        if (start) begin
            multiply_step <= 0;
            a <= a_in;
            b <= b_in;
        end else if (multiply_step < N) begin
            if (multiply_step == 0) accumulate_step <= 0;
            multiply_step <= multiply_step + 1;
            a <= {a[0 +: N*W-W], a[254 -: W]};
            b <= {b[0 +: W], b[W +: 255-W]};
        end
        if (accumulate_step < N) begin
            accumulate_step <= accumulate_step + 1;
            if (accumulate_step == N-1) prereduce <= 1;
        end
    end

    genvar j; generate for (j = 0; j < N; j = j + 1) begin: mul_mid
        always @(posedge clock) begin
            if (multiply_step < N) partialProduct[j] <= b[0 +: W] * a[j*W +: W];
            if (accumulate_step < N) begin
                if     (accumulate_step == 0) acc[j] <= partialProduct[j];
                else if (j < accumulate_step) acc[j] <= acc[j] + mult19(partialProduct[j]);
                else                          acc[j] <= acc[j] + partialProduct[j];
            end
        end
    end endgenerate

    reg prereduce = 0;
    reg [2*W + LOGN + LOGC - 1:0] carry = 0, carryIgnore = 0;
    wire [2*W + LOGN + LOGC -1:0] preCarry = ((acc[N-2] >> W) + acc[N-1]) >> W;
    always @ (posedge clock) begin
        if (prereduce) begin
            carryIgnore <= preCarry;
            carry <= mult19(preCarry);
            prereduce <= 0;
            reduce_step <= 0;
            borrow <= 0;
        end
    end

    reg [LOGN-1:0] reduce_step = N;
    reg [254:0] out_, outP; // two options for the output: r, and r-P
    reg wrapP = 0, borrow = 0;
    wire [2*W + LOGN + LOGC - 1:0] partial = carry + acc[reduce_step];
    wire [W:0 ]partialP = partial[W-1:0] - P[reduce_step*W +: W] - borrow;
    always @ (posedge clock) begin
        if (reduce_step < N) begin
            reduce_step <= reduce_step + 1;
            carry <= partial  >> W;
            out_ <= {partial [W-1:0], out_[254:W]};
            outP <= {partialP[W-1:0], outP[254:W]};
            borrow <= partialP[W];
        end
        if (reduce_step == N-1) begin
            done <= 1;
            wrapP <= (partial  >> W) > carryIgnore || partialP[W] == 0;
        end else done <= 0;
    end
    assign out = wrapP ? outP : out_;
endmodule
