/* Copyright (C) 2023 Michael Bell

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

parameter CLK_BIT=19;

module tt_top (
        input clk12MHz,
        input button1,
        input button2,
        input button3,
        input button4,
        output led1,
        output led2,
        output led3,
        output led4,
        output led5,
        output led6,
        output led7,
        output led8,
        output lcol1,
        output lcol2,
        output lcol3,
        output lcol4,

        input tt_clk,
        input tt_mgmt,
        input tt_rst_n,
        output [7:0] tt_out,
        input [11:0] tt_in 
        );

    wire [7:0] uio_in;
    wire [7:0] uio_out;
    assign uio_in = {4'd0, tt_in[11:8]};

    tt_um_MichaelBell_hovalaag hovalaag(
        .ui_in(tt_in[7:0]),
        .uo_out(tt_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .ena(tt_mgmt),
        .clk(tt_clk),
        .rst_n(tt_rst_n)
    );

    // Track expected stage of Hova execution
    reg [2:0] stage;
    always @(posedge tt_clk)
        if (!tt_rst_n)
            stage <= 0;
        else
            if (stage == 4)
                stage <= 0;
            else
                stage <= stage + 1;

    // Track pc
    reg [7:0] pc;
    always @(negedge tt_clk)
        if (!tt_rst_n)
            pc <= 0;
        else
            if (stage == 3)
                pc <= tt_out;

    // Track 7seg output
    reg [7:0] out_as_7seg;
    always @(negedge tt_clk)
        if (!tt_rst_n)
            out_as_7seg <= 0;
        else
            if (stage == 4)
                out_as_7seg <= tt_out;

    wire [7:0] leds1_7seg;
    wire [7:0] leds2_7seg;
    wire [7:0] leds3_7seg;
    wire [7:0] leds4_7seg;
    big7_seg seg_decode(out_as_7seg, leds1_7seg, leds2_7seg, leds3_7seg, leds4_7seg);

    // map the output of ledscan to the port pins
    wire [7:0] leds_out;
    wire [3:0] lcol;
    assign { led8, led7, led6, led5, led4, led3, led2, led1 } = leds_out[7:0];
    assign { lcol4, lcol3, lcol2, lcol1 } = lcol[3:0];

    LedScan scan (
                .clk12MHz(clk12MHz),
                .leds1(button1 ? tt_out         : leds1_7seg),
                .leds2(button1 ? 8'b0           : leds2_7seg),
                .leds3(button1 ? pc             : leds3_7seg),
                .leds4(button1 ? {5'b0, stage}  : leds4_7seg),
                .leds(leds_out),
                .lcol(lcol)
        );

endmodule