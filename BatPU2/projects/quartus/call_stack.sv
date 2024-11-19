module call_stack(
    input clk, clk_en, execute, mode,
    input [9:0] data_in,
    output [9:0] data_out
);
    reg [9:0] callstack [15:0];
    reg [3:0] pointer = 0;

    always_ff @(posedge clk) begin : CSTACKProcess
        if(clk_en && execute) begin
            pointer <= pointer + (mode ? 4'hf : 4'h1);
            callstack[pointer] <= data_in;
        end
    end

    assign data_out = callstack[pointer];

endmodule : call_stack
