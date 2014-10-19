`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module femul_test;
    parameter N = 7;
    reg [$bits(N):0] i = 0;
    reg [254:0] as [N:0];
    reg [254:0] bs [N:0];
    reg [254:0] outs [N:0];

    initial begin
        as[0]   = 15;
        bs[0]   = 7;
        outs[0] = 22;
        
        as[2]   = (255'b1<<254);
        bs[2]   = (255'b1<<254);
        outs[2] = 19;

        as[2]   = (255'b1<<254)-1;
        bs[2]   = (255'b1<<254)-1;
        outs[2] = 17;

        as[3]   = 255'h7fffffffffffffffffffffffffffffffffff00000000000000ffffffffffffff;
        bs[3]   = 255'h7fffffffffffffffffffffffffffffffffff00000000000000ffffffffffffff;
        outs[3] = 255'h7ffffffffffffffffffffffffffffffffffe0000000000000200000000000011;

        as[4]   = (255'b1<<255) - 20;
        bs[4]   = 1;
        outs[4] = 0;

        as[5]   = (255'b1<<255) - 20;
        bs[5]   = 20;
        outs[5] = 19;

        as[6]   = 255'h6483b328032df78f6abb1342dc54964127be97507e17c1b4cf481339f1fa20de;
        bs[6]   = 255'h7579007f91255656a870d105b188a20ba82f0e6b02f313d0e94408add33d4b0a;
        outs[6] = 255'h59fcb3a794534de6132be4488ddd384ccfeda5bb810ad585b88c1be7c5376bfb;
    end

    wire [254:0] out;
    wire done;
    reg clock = 0, start = 1;
    feadd feadd(clock, start, as[i], bs[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        if (done) begin
            $display("(0x%x + 0x%x)%%((1<<255)-19) == 0x%x", as[i], bs[i], out);
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
