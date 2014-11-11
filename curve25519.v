`default_nettype none

// This code assumes that addition takes $k$ cycles, subtraction takes $k$
// cycles, and multiplication has a latency of $2k$ and can take a new input
// each $k$ cycles. Currently, $k=17$.

module curve25519(input wire clock, start,
                  input wire [254:0] n, // scalar
                  input wire [254:0] q, // point
                  output reg done = 0,
                  output wire [254:0] out);
    reg [254:0] r[0:6];
    localparam PSX=0, SX=1, SZ=2, MX=3, MZ=4, PMX=5, PSZ=6;
    localparam A_MINUS_FOUR_OVER_TWO=7, Q=8, OUT=6 /* aliases PSZ */;
    localparam P_MINUS_TWO = (256'b1<<255) - 21;
    assign out = r[OUT];
    wire [254:0] mul_snd = mul2 == 8 ? q : mul2 == 7 ? 121665 : r[mul2];
    reg add_start=0, sub_start=0, mul_start=0;
    reg [$bits(Q):0] add1=0, add2=0, mul1=0, mul2=0;
    wire add_done, sub_done, mul_ready, mul_done;
    wire [254:0] add_out, sub_out, mul_out;
    feadd feadd(clock, add_start, r[add1], r[add2], add_done, add_out);
    fesub fesub(clock, sub_start, r[add1], r[add2], sub_done, sub_out);
    femul femul(clock, mul_start, r[mul1], mul_snd, mul_ready, mul_done, mul_out);

    reg [1:0] state = 3; localparam PREPARE=0, MAINLOOP=1, INVERT=2, FINAL=3;
    reg [7:0] i = 254; // mainloop: iteration number / index into n [254..0]
    reg [3:0] stage = 0; // mainloop: process counter in iteration
    reg inv_square = 0;

    always @(posedge clock) begin
        if (start) begin
            state <= 0;
            r[SX] <= 1;
            r[SZ] <= 0;
            r[MX] <= q;
            r[MZ] <= 1;
            r[PSX] <= 1;
            r[PMX] <= q;
            add1 <= MX;
            add2 <= MZ;
            add_start <= 1;
            state <= PREPARE;
        end
        if (state == PREPARE && add_done) begin
            state <= MAINLOOP;
            i <= 254;
            stage <= 1;
            // start stage1
            if (n[254]) begin
                {r[PSX], r[SX], r[SZ], r[PMX], r[MX], r[MZ]} <= 
                {r[PMX], add_out, r[MZ], r[PSX], r[SX], r[SZ]};
            end
            sub_start <= 1; add1 <= PSX; add2 <= SZ;
            mul_start <= 1; mul1 <=  SX; mul2 <= SX;
        end
        if (state == MAINLOOP && stage == 1) begin
            if (sub_done) begin
                r[SZ] <= sub_out;
                mul_start <= 1; mul1 <= SZ; mul2 <= SZ;
            end
            if (mul_done) begin
                r[PSX] <= r[SX];
                r[SX] <= mul_out;
                stage <= 2;
                sub_start <= 1; add1 <= PMX; add2 <= MZ;
                mul_start <= 1; mul1 <=  MX; mul2 <= SZ;
            end
        end
        if (state == MAINLOOP && stage == 2 && mul_done) begin
            r[PSZ] <= r[SZ];
            r[MZ] <= sub_out;
            r[SZ] <= mul_out;
            stage <= 3;
            mul_start <= 1; mul1 <= MZ; mul2 <= PSX;
        end
        if (state == MAINLOOP && stage == 3 && mul_done) begin
            r[MX] <= mul_out;
            stage <= 4;
            sub_start <= 1; add1 <= SX; add2 <= SZ;
            mul_start <= 1; mul1 <= SX; mul2 <= SZ;
        end
        if (state == MAINLOOP && stage == 4 && mul_done) begin
            r[ MZ] <= mul_out;
            r[PSZ] <= r[SZ];
            r[ SZ] <= sub_out;
            stage <= 5;
            add_start <= 1; add1 <= MX; add2 <= MZ;
            mul_start <= 1; mul1 <= SZ; mul2 <= A_MINUS_FOUR_OVER_TWO;
        end
        if (state == MAINLOOP && stage == 5 && mul_done) begin
            r[PMX] <= r[MX];
            r[ MX] <= add_out;
            r[PSX] <= r[SX];
            r[ SX] <= mul_out;
            stage <= 6;
            sub_start <= 1; add1 <= MZ; add2 <= PMX;
            mul_start <= 1; mul1 <= MX; mul2 <=  MX;
        end
        if (state == MAINLOOP && stage == 6 && mul_done) begin
            r[ MZ] <= sub_out;
            r[PSZ] <= r[SZ];
            r[ SZ] <= mul_out;
            stage <= 7;
            add_start <= 1; add1 <= SZ; add2 <= PSX;
            mul_start <= 1; mul1 <= MZ; mul2 <=  MZ;
        end
        if (state == MAINLOOP && stage == 7 && mul_done) begin
            r[SZ] <= add_out;
            r[MX] <= mul_out;
            stage <= 8;
            mul_start <= 1; mul1 <= SZ; mul2 <= PSZ;
        end
        if (state == MAINLOOP && stage == 8 && mul_done) begin
            r[MZ] <= mul_out;
            stage <= 9;
            mul_start <= 1; mul1 <= MZ; mul2 = Q;
        end
        if (state == MAINLOOP && stage == 9 && mul_done) begin
            r[PSX] <= r[SX];
            r[SZ]  <= mul_out;
            add_start <= 1; add1 <= SX; add2 <= SZ;
            stage <= 10;
        end
        if (state == MAINLOOP && stage == 10 && mul_done) begin
            r[MZ] <= mul_out;
            r[SX]  <= add_out;
            add_start <= 1; add1 <= MX; add2 <= MZ;
            stage <= 11;
        end
        if (state == MAINLOOP && stage == 11 && add_done) begin
            if (i != 0) begin
                stage <= 1;
                sub_start <= 1; add1 <= PSX; add2 <= SZ;
                mul_start <= 1; mul1 <=  SX; mul2 <= SX;
                i <= i-1;
                if (n[i] == n[i-1]) begin
                    r[PMX] <= r[MX];
                    r[ MX] <= add_out;
                end else begin
                    {r[PSX], r[SX],  r[SZ], r[PMX], r[MX], r[MZ]} <= 
                    {r[MX], add_out, r[MZ], r[PSX], r[SX], r[SZ]};
                end
            end else begin
                state <= INVERT;
                i <= 254;
                r[OUT] <= 1;
                inv_square <= 0;
                mul_start <= 1; mul1 <= OUT; mul2 <= SZ;
            end
        end
        if (state == INVERT && mul_done &&  inv_square) begin
            inv_square <= 0;
            r[OUT] <= mul_out;
            mul_start <= 1; mul1 <= OUT; mul2 <= SZ;
        end
        if (state == INVERT && mul_done && !inv_square) begin
            inv_square <= 1;
            if (P_MINUS_TWO[i]) r[OUT] <= mul_out;
            if (i != 0) begin
                i <= i-1;
                mul_start <= 1; mul1 <= OUT; mul2 <= OUT;
            end else begin
                state <= FINAL;
                mul_start <= 1; mul1 <= PSX; mul2 <= OUT;
            end
        end
        if (state == FINAL && mul_done) begin
            r[OUT] <= mul_out;
            done <= 1;
        end
        if (add_start) add_start <= 0;
        if (sub_start) sub_start <= 0;
        if (mul_start) mul_start <= 0;
    end
endmodule
