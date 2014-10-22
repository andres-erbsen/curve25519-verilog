`default_nettype none

module femul(input wire clock, start,
             input wire [254:0] a_in, b_in,
             output reg ready = 1,
             output reg done = 0,
             output wire [254:0] out);
    parameter W = 17; // hardware multiplier input word size
    parameter N = 15; // number of words used to represent one field element
    parameter C = 19; // pseudo-Mersenne coefficient
    `define multC(a) (a + (a<<1) + (a<<4))
    parameter P = (255'b1<<(N*W)) - C; // 2^255 - 19
    parameter LOGC = 4;
    parameter LOGN = 4;
    parameter MIDW = 2*W + LOGN + LOGC;

    reg [254:0] a = 0;
    reg [254:0] b = 0;
    reg [LOGN-1:0] multiply_step = N, accumulate_step = N, reduce_step = N;
    reg [2*W-1:0] partialProduct [N-1:0];
    reg [MIDW-1:0] acc [N-1:0], accumulated [N-1:0];

    reg prereduce = 0, borrow = 0, wrapP = 0;
    reg [MIDW-1:0] carry = 0, carryIgnore = 0;
    reg [254:0] out_, outP; // two options for the output: r, and r-P

    wire [MIDW-1:0] partialSum = carry + accumulated[reduce_step];
    wire [W:0] partialSumP = partialSum[W-1:0] - P[reduce_step*W +: W] - borrow;
    wire [MIDW-1:0] preCarry = ((accumulated[N-2] >> W) + accumulated[N-1]) >> W;
    assign out = wrapP ? outP : out_;

    genvar j; generate for (j = 0; j < N; j = j + 1) begin: mul_mid
        wire [2*W + LOGN + LOGC - 1:0] accNext = acc[j] +
            ((accumulate_step  > j) ? `multC(partialProduct[j]) : partialProduct[j]);
        always @(posedge clock) begin
            if (multiply_step < N) partialProduct[j] <= b[0 +: W] * a[j*W +: W];
            if (accumulate_step == 0)        acc[j] <= partialProduct[j];
            else if (accumulate_step  < N-1) acc[j] <= accNext;
            else if (accumulate_step == N-1) accumulated[j] <= accNext;
        end
    end endgenerate

    always @ (posedge clock) begin
        if (start) begin
            ready <= 0;
            multiply_step <= 0;
            a <= a_in;
            b <= b_in;
        end
        
        if (multiply_step < N) begin
            multiply_step <= multiply_step + 1;
            if (multiply_step == 0) accumulate_step <= 0;
            a <= {a[0 +: N*W-W], a[254 -: W]};
            b <= {b[0 +: W], b[W +: 255-W]};
        end

        if (accumulate_step < N) begin
            accumulate_step <= accumulate_step + 1;
            if (accumulate_step == N-2) ready <= 1;
            if (accumulate_step == N-1) prereduce <= 1;
        end

        if (prereduce) begin
            carryIgnore <= preCarry;
            carry <= `multC(preCarry);
            prereduce <= 0;
            reduce_step <= 0;
            borrow <= 0;
        end

        if (reduce_step < N) begin
            reduce_step <= reduce_step + 1;
            carry <= partialSum >> W;
            out_ <= {partialSum [W-1:0], out_[254:W]};
            outP <= {partialSumP[W-1:0], outP[254:W]};
            borrow <= partialSumP[W];
        end

        if (reduce_step == N-1) begin
            done <= 1;
            wrapP <= (partialSum >> W) > carryIgnore || partialSumP[W] == 0;
        end else done <= 0;
    end
    `undef multC
endmodule
