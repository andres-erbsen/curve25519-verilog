`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module femul_test;
    parameter N = 5;
    reg [$bits(N):0] i = 0;
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

        as[4]   = 255'h6483b328032df78f6abb1342dc54964127be97507e17c1b4cf481339f1fa20de;
        bs[4]   = 255'hb47d26181c9f63bb1405345faca4ffd0fe748b6652fa7d2decf0e2c865e988d;
        outs[4] = 255'h7587e6935be3c0628e7fa76da3931343283adb49a03f048998eb0f9b51a209ef;
    end

    wire [254:0] out;
    wire done;
    reg clock = 0, start = 1;
    femul femul(clock, start, as[i], bs[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        if (done) begin
            $display("(0x%x * 0x%x)%%((1<<255)-19) == 0x%x", as[i], bs[i], out);
            `assert(out === outs[i])
            if (i < N-1) begin
                i <= i + 1;
                start <= 1;
            end else begin
                $finish;
            end
        end
        if (start) start <= 0;
    end

    // initial begin $monitor("done=%b reduce_step=%d carry=%x partial=%x      out=%x", done, femul.reduce_step, femul.carry, femul.partial, out); end
endmodule
