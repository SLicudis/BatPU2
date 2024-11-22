module icache( //64 bytes, 4x8, 16-bit
    input clk, clk_en, req,
    input [9:0] address_in,
    input [15:0] from_mem,
    output [15:0] inst_out,
    output [9:0] address_out,
    output busy, mreq
);
    reg [15:0] cache [31:0];
    reg [5:0] tags [3:0]; //Valid bit: 5
    reg busy_state = 0;
    wire miss = (tags[index] != {1'b1, address_in[9:5]}) && req; //Detect for cache miss if tags aren't matching.

    wire [1:0] index = address_in[4:3]; //Tag index section of the reading address

    reg [2:0] offs_pointer = 0; //Points at the lower 4 bits of the address (For line offsets in fetching)
    reg end_phase = 0; //Wait state 2

    reg [15:0] out_reg = 0; //Output register for BRAM

    assign mreq = (busy_state || miss) && clk_en; //Memory requests are send when a miss happens
    assign busy = busy_state && clk_en; //The core must still output req to the cache, even tho it's stalled.
    assign address_out = busy_state ? ({address_in[9:3], offs_pointer}+1) : {address_in[9:3], offs_pointer}; //Address for fetching
    assign inst_out = out_reg;

    always_ff @(posedge clk) begin : StateMachine
        if(clk_en) begin
            out_reg <= cache[address_in[4:0]]; //Update output register
            if(!busy_state) begin   //Check stage
                busy_state <= miss; //Set busy state if miss
                end_phase <= 0; //Reset (just in case)
                offs_pointer <= 0; //Reset (just in case)
            end else if(!end_phase) begin //Fetch phases
                tags[index] <= {1'b1, address_in[9:5]}; //Update the tag
                offs_pointer <= offs_pointer + 1; //Increment offset pointer for the next word
                cache[{index, offs_pointer}] <= from_mem; //Write the input word to cache
                if(offs_pointer == 7) end_phase <= 1; //Start ending phase
            end else if(end_phase) begin   //Ending phase of the cache
                busy_state <= 0; //Reset busy state
                end_phase <= 0;
                offs_pointer <= 0; //Reset the offset pointer (just in case)
            end
        end
    end
/*
A cache miss stalls the core for 17 cycles

INITIAL PHASE:
-busy_state is set, indicating that there's a cache miss and the CPU needs to be stalled
-offs_pointer is reset (just in case)
-ending_phase is reset (just in case)

FETCHING PHASE:
-the old tag is replaced with the new one
-offs_pointer points at the line ofset in both cache and main memory.
-offs_poiinter increments and the input word is transfered to cache
-this phase takes 16 clock cycles

ENDING PHASE:
-busy_state is reset
-offs_pointer is reset
*/

endmodule : icache
