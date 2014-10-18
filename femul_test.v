`default_nettype none

module femul_test;
    reg clock = 0, start = 0;
    reg [254:0] a = 19074120634824822126221600568435182786804268236321474068950658706909933706558;
    reg [254:0] b = 42341415808548244942861149601678448512076970397948787689406181319388671497316;
    wire [254:0] out;
    wire done;
    femul femul(clock, start, a, b, done, out);

    always #1 clock <= !clock;
    initial begin
        $monitor("done=%b mul_step=%x reduce_step=%d carry=%x mid[1]=%2d out=%0x", done, femul.multiply_step, femul.reduce_step, femul.carry, femul.mid[1], out);
        #1 start <= 1;
        #1 start <= 0;
    end
    always @(posedge done) $finish;
endmodule
