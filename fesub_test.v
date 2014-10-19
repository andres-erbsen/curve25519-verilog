`default_nettype none
`define assert(condition) if(!((|{condition})===1)) begin $display("FAIL"); $finish(1); end

module fesub_test;
    parameter N = 5;
    reg [$bits(N):0] i = 0;
    reg [254:0] as [N:0];
    reg [254:0] bs [N:0];
    reg [254:0] outs [N:0];

    initial begin
        as[0]   = 15;
        bs[0]   = 7;
        outs[0] = 8;
        
        as[2]   = (255'b1<<254);
        bs[2]   = (255'b1<<254);
        outs[2] = 0;

        as[2]   = (255'b1<<254)-1;
        bs[2]   = (255'b1<<254);
        outs[2] = (255'b1<<255) - 20;

        as[3]   = 255'h6a5d5f72ba35d2f0677bfdc4304730afdba87b2809b7169deef37e93436ccd93;
        bs[3]   = 255'h646f6b0a2d0c730d65be840a150bcf00bb812d4d9749ac0108d127f432407be3;
        outs[3] = 255'h05edf4688d295fe301bd79ba1b3b61af20274dda726d6a9ce622569f112c51b0;

        as[4]   = 255'h26f6835da37cc471b711144e6b57b49f12abb7c709fb30563091e6a8ffb39a6a;
        bs[4]   = 255'h46f448e85e4abb77eed5b70a85d648f174e31745eeb769fbcfec2d92e1a17490;
        outs[4] = 255'h60023a75453208f9c83b5d43e5816bad9dc8a0811b43c65a60a5b9161e1225c7;
    end

    wire [254:0] out;
    wire done;
    reg clock = 0, start = 1;
    fesub fesub(clock, start, as[i], bs[i], done, out);
    always #1 clock <= !clock;

    always @(posedge clock) begin
        if (done) begin
            $display("(0x%x - 0x%x)%%((1<<255)-19) == 0x%x", as[i], bs[i], out);
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
