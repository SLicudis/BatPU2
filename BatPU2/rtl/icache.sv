module icache #(
    parameter DATABITWIDTH = 16, //Word size
    parameter ADDRESSWIDTH = 10, //Width of the address
    parameter LINES = 4, //Amount of lines
    parameter LINESIZE = 8, //Words per line

    parameter IDXWIDTH = $clog2(LINES),
    parameter OFFSWIDTH = $clog2(LINESIZE),
    parameter CACHEAMT = LINES*LINESIZE
)(
    input clk, clk_en, sync_rst,
    input req, //Request data
    input inv, //Invalidate a line
    input [DATABITWIDTH-1:0] data_in, //Data from memory
    input [ADDRESSWIDTH-1:0] inst_addr, //Instruction address from the core
    input [IDXWIDTH-1:0] inv_idx, //Invalidation address index from the core
    output [DATABITWIDTH-1:0] data_out, //To the core
    output [ADDRESSWIDTH-1:0] inst_addr_out, //Address to memory
    output pre_busy, //Indicate if there was a cache miss (Before starting the protocol)
    output busy //Indicate if it's on fetching mode
);
    reg [DATABITWIDTH-1:0] cache [CACHEAMT-1:0];
    reg [DATABITWIDTH-1:0] output_buffer; //Output buffer to allow the use of BRAM
    reg [ADDRESSWIDTH-IDXWIDTH-OFFSWIDTH:0] tags [LINES-1:0]; //The MSB indicates if the tag is valid or not
    reg [ADDRESSWIDTH-1:0] address_buffer; //Safety address buffer in case of a miss

    reg [1:0] state; //State machine register
    typedef enum bit[1:0] {IDLE, START, FETCH, FINISH} states;
    reg [OFFSWIDTH-1:0] offs_pointer;

    wire miss = (tags[inst_addr[IDXWIDTH+OFFSWIDTH-1:OFFSWIDTH]] != {1'b1, inst_addr[ADDRESSWIDTH-1:IDXWIDTH+OFFSWIDTH]}); //Compare tags
    
    wire [ADDRESSWIDTH-IDXWIDTH-OFFSWIDTH:0] tag_reset_array [LINES-1:0]; //This array only contains 0s and it's used for resetting the tags
    genvar i;
    generate
        for(i = 0; i < IDXWIDTH; i++) begin : TagResetArray
            assign tag_reset_array[i] = 0; //Assign each wire to 0
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(clk_en) begin
            output_buffer <= cache[|busy ? address_buffer[IDXWIDTH+OFFSWIDTH-1:0] : inst_addr[IDXWIDTH+OFFSWIDTH-1:0]]; //Output buffer to allow the use of BRAM
            if(sync_rst) begin //Reset protocol
                tags <= tag_reset_array; //All the tags are reset
                state <= 0;
                offs_pointer <= 0;
            end else begin
                if(inv) tags[inv_idx] <= 0; //Invalidate a line
                case(state) //State machine of the cache
                IDLE: if(miss && req) begin
                    state <= START;
                    offs_pointer <= (2**OFFSWIDTH)-1;
                    address_buffer <= inst_addr; //Update the address buffer (For safety reasons)
                    end
                START: begin
                    state <= FETCH;
                    offs_pointer <= 0;
                    end
                FETCH: begin
                    offs_pointer <= offs_pointer + 1; //Increment the offset pointer
                    cache[{address_buffer[IDXWIDTH+OFFSWIDTH-1:OFFSWIDTH], offs_pointer}] <= data_in; //Move the data to cache
                    tags[address_buffer[IDXWIDTH+OFFSWIDTH-1:OFFSWIDTH]] <= {1'b1, address_buffer[ADDRESSWIDTH-1:IDXWIDTH+OFFSWIDTH]}; //Update the selected tag
                    if(offs_pointer == (2**OFFSWIDTH)-1) state <= FINISH;
                    end
                FINISH: begin
                    state <= 0;
                    end
                endcase
            end
        end
    end

    assign inst_addr_out = {address_buffer[ADDRESSWIDTH-1:OFFSWIDTH], offs_pointer+1'b1};
    assign data_out = output_buffer;
    assign busy = |state;
    assign pre_busy = miss && !busy;

endmodule : icache

