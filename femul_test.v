`default_nettype none

module femul_test;
    reg clock = 0, start = 0;
    reg [254:0] a = 3, b = 4;
    wire [254:0] out;
    wire done;
    femul femul(clock, start, a, b, done, out);

    always #1 clock <= !clock;
    initial begin
        $monitor("done=%b mul_step=%x reduce_step=%d carry=%x mid[0]=%2d out=%0x", done, femul.multiply_step, femul.reduce_step, femul.carry, femul.mid[0], out);
        #1 start <= 1;
        #1 start <= 0;
    end
    always @(posedge done) $finish;
endmodule
