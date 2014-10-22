`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module femul_test;
    parameter N = 6;
    reg [$bits(N):0] in_i = 0, out_i = 0;
    reg [254:0] as [N:0];
    reg [254:0] bs [N:0];
    reg [254:0] outs [N:0];

    initial begin
        as[0]   = (255'd1<<128);
        bs[0]   = (255'd1<<128);
        outs[0] = 255'h026;

        as[1]   = (255'd1<<255) - 1;
        bs[1]   = 1;
        outs[1] = 255'h012;

        as[2]   = (1<<128) - 1;
        bs[2]   = (1<<128) + 1;
        outs[2] = 255'h025;

        as[3]   = (1<<250) - 1997;
        bs[3]   = 254'hfffffffff - 17;
        outs[3] = 255'h37ffffffffffffffffffffffffffffffffffffffffffffffffff833980008c57;

        as[4]   = 255'b1 << 254;
        bs[4]   = 2;
        outs[4] = 19;

        as[5]   = 255'h6483b328032df78f6abb1342dc54964127be97507e17c1b4cf481339f1fa20de;
        bs[5]   = 255'hb47d26181c9f63bb1405345faca4ffd0fe748b6652fa7d2decf0e2c865e988d;
        outs[5] = 255'h7587e6935be3c0628e7fa76da3931343283adb49a03f048998eb0f9b51a209ef;
    end

    wire [254:0] out;
    wire ready, done;
    reg clock = 0, start = 0;
    femul femul(clock, start, as[in_i], bs[in_i], ready, done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        if (ready && in_i < N) start <= 1;
        if (start) begin
            start <= 0;
            in_i <= in_i + 1;
        end
        if (done) begin
            $display("(0x%x * 0x%x)%%((1<<255)-19) == 0x%x", as[out_i], bs[out_i], out);
            `assert(out === outs[out_i])
            if (out_i == N-1) begin $display("%0d/%0d cycles/femul", $time/2, N); $finish; end
            else out_i <= out_i + 1;
        end
    end
   // initial begin $monitor("i=%d o=%d ready=%b start=%b done=%b", in_i, out_i, ready, start, done); end
   // initial begin $monitor("carry=%x partial=%x borrow=%x partialP=%x  out=%x (%b)", femul.carry, femul.partialSum, femul.borrow, femul.partialSumP, out, femul.wrapP); end
endmodule
