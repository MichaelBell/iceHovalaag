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
        output lcol4
        );

    wire [7:0] tt_inputs;
    wire [7:0] tt_outputs;

    MichaelBell_hovalaag hovalaag(
        .io_in(tt_inputs),
        .io_out(tt_outputs)
    );

    // Counter
    reg [31:0] counter = 0;
    always @ (posedge clk12MHz)
        counter <= counter + 1;

    // Setup TT inputs
    wire slow_clk = counter[CLK_BIT];
    wire reset_n = counter[31:CLK_BIT] > 20;
    reg [5:0] tt_in;
    assign tt_inputs[0] = slow_clk;
    assign tt_inputs[1] = reset_n;
    assign tt_inputs[2] = reset_n ? tt_in[0] : 1;
    assign tt_inputs[7:3] = tt_in[5:1];

    // Track expected stage of Hova execution
    reg [3:0] stage;
    always @(posedge slow_clk)
        if (!reset_n)
            stage <= 0;
        else
            if (stage == 9)
                stage <= 0;
            else
                stage <= stage + 1;

    // Instruction ROM, doesn't seem to be inferring
    reg [15:0] instr_low [0:7];
    reg [15:0] instr_high [0:7];

    //                     ALU- A- B- C- D W- F- PC O I X K----- L-----
    initial {instr_high[0], instr_low[0]} = 32'b0000_00_00_00_0_00_01_00_0_0_0_000000_000000; // F=ZERO(ALU)
    initial {instr_high[1], instr_low[1]} = 32'b0111_01_00_00_0_01_00_01_1_0_0_000000_000001; // A=A+B+F,W+A+B+F,OUT1=W,JMP 1
    initial {instr_high[2], instr_low[2]} = 32'b0000_11_00_00_0_00_00_00_0_0_0_000000_000000;  // A=IN1
    initial {instr_high[3], instr_low[3]} = 32'b0000_00_10_00_0_00_00_00_0_0_0_000000_000000;  // B=A
    initial {instr_high[4], instr_low[4]} = 32'b0101_01_01_00_0_00_00_00_0_0_0_000000_000000;  // A=B=A+B
    initial {instr_high[5], instr_low[5]} = 32'b0101_01_01_00_0_00_00_00_0_0_0_000000_000000;  // A=B=A+B
    initial {instr_high[6], instr_low[6]} = 32'b0101_00_00_00_0_01_00_00_0_0_0_000000_000000;  // W=A+B
    initial {instr_high[7], instr_low[7]} = 32'b0000_00_00_00_0_00_00_00_1_0_0_000000_000000;  // OUT1=W;

    reg [31:0] cur_instr;
    always @(posedge slow_clk)
        cur_instr <= {instr_high[pc[2:0]], instr_low[pc[2:0]]};

    always @(negedge slow_clk)
        if (!reset_n)
            tt_in <= 0;
        else
            if (stage == 0)      tt_in <= cur_instr[5:0];
            else if (stage == 1) tt_in <= cur_instr[11:6];
            else if (stage == 2) tt_in <= cur_instr[17:12];
            else if (stage == 3) tt_in <= cur_instr[23:18];
            else if (stage == 4) tt_in <= cur_instr[29:24];
            else if (stage == 5) tt_in <= {4'b0000, cur_instr[31:30]};
            else tt_in <= 0;

    // Track pc
    reg [7:0] pc;
    always @(negedge slow_clk)
        if (!reset_n)
            pc <= 0;
        else
            if (stage == 7)
                pc <= tt_outputs;

    // Track 7seg output
    reg [7:0] out_as_7seg;
    always @(negedge slow_clk)
        if (!reset_n)
            out_as_7seg <= 0;
        else
            if (stage == 0)
                out_as_7seg <= tt_outputs;

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
                .leds1(button1 ? tt_outputs     : leds1_7seg),
                .leds2(button1 ? counter[29:22] : leds2_7seg),
                .leds3(button1 ? pc             : leds3_7seg),
                .leds4(button1 ? {4'b0, stage}  : leds4_7seg),
                .leds(leds_out),
                .lcol(lcol)
        );

endmodule