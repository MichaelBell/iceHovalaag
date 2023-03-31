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

module tt_top (
        input clk12MHz,
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
    wire reset_n = counter[31:22] > 20;
    assign tt_inputs[0] = counter[22];
    assign tt_inputs[1] = reset_n;
    assign tt_inputs[2] = !reset_n;
    assign tt_inputs[7:3] = 0;

    // Track expected stage of Hova execution
    reg [3:0] stage;
    always @(posedge counter[22])
        if (!reset_n)
            stage <= 9;
        else
            if (stage == 9)
                stage <= 0;
            else
                stage <= stage + 1;

    // Track pc
    reg [7:0] pc;
    always @(negedge counter[22])
        if (!reset_n)
            pc <= 0;
        else
            if (stage == 6)
                pc <= tt_outputs;

    // map the output of ledscan to the port pins
    wire [7:0] leds_out;
    wire [3:0] lcol;
    assign { led8, led7, led6, led5, led4, led3, led2, led1 } = leds_out[7:0];
    assign { lcol4, lcol3, lcol2, lcol1 } = lcol[3:0];

    LedScan scan (
                .clk12MHz(clk12MHz),
                .leds1(tt_outputs),
                .leds2(counter[29:22]),
                .leds3(pc),
                .leds4({4'b0, stage}),
                .leds(leds_out),
                .lcol(lcol)
        );

endmodule