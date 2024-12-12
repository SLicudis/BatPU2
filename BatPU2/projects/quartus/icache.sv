module icache #(
    parameter DATABITWIDTH = 16,
    parameter ADDRESSWIDTH = 10,
    parameter LINES = 4,
    parameter LINESIZE = 8,
    parameter EXT_MEMORY_LATENCY = 1 //How many clock cycles it takes to fetch from memory
)(
    input clk, clk_en, sync_rst,
    input req, invalidate,
    input [ADDRESSWIDTH-1:0] address_in, //Address from the core
    input [ADDRESSWIDTH-1:0] invalidate_address, //Data address from the core
    input [DATABITWIDTH-1:0] data_in, //Data from memory
    output [ADDRESSWIDTH-1:0] address_out, //Address to memory
    output [DATABITWIDTH-1:0] data_out, //Instruction to core
    output busy //Stall the core
);
    localparam LINEADDR = $clog2(LINES);
    localparam OFFSADDR = $clog2(LINESIZE);
    localparam TAGSIZE = ADDRESSWIDTH - LINEADDR - OFFSADDR;
    localparam LATENCY_CTR_SIZE = adjustsize($clog2(EXT_MEMORY_LATENCY));

    function integer adjustsize(integer size);
        if(size <= 1) adjustsize = 1;
        else adjustsize = size;
    endfunction

    //Main section
    reg [DATABITWIDTH-1:0] cache [LINES-1:0][LINESIZE-1:0]; //Contains the data
    reg [TAGSIZE-1:0] tag [LINES-1:0]; //Contains the tags (MSB = valid indicator)
    reg [LINES-1:0] tag_valid;

    reg [ADDRESSWIDTH-1:0] address_buffer; //Request address buffer
    reg [DATABITWIDTH-1:0] data_out_buffer; //Data buffer for BRAM
    reg [TAGSIZE-1:0] tag_buffer; //Tag buffer for BRAM

    wire [TAGSIZE-1:0] input_tag = address_buffer[ADDRESSWIDTH-1:LINEADDR+OFFSADDR]; //Tag of the address
    wire [LINEADDR-1:0] input_index = address_buffer[LINEADDR+OFFSADDR-1:OFFSADDR]; //Index part of the address
    wire [OFFSADDR-1:0] input_offset = address_buffer[OFFSADDR-1:0]; //Offset part of the address

    wire [LINEADDR-1:0] selected_index = (fetch_transfer_finished && (central_state == TAG_REPLACE)) ? input_index : address_in[LINEADDR+OFFSADDR-1:OFFSADDR];
    wire [OFFSADDR-1:0] selected_offset = (fetch_transfer_finished && (central_state == TAG_REPLACE)) ? input_offset : address_in[OFFSADDR-1:0];

    always_ff @(posedge clk) begin : Buffering
        if(clk_en) begin
            if(!busy && req) begin
                address_buffer <= address_in; //Can't be updated if busy
                tag_buffer <= tag[address_in[LINEADDR+OFFSADDR-1:OFFSADDR]];
            end
            if((!busy && req) || (fetch_transfer_finished && (central_state == TAG_REPLACE))) data_out_buffer <= cache[selected_index][selected_offset]; //Updated if not busy and there's a request or when the fetching process is finished
        end
    end

    assign data_out = data_out_buffer;
    assign address_out = {input_tag, input_index, fetch_offset_pointer}; //Address connected to the external memory

    //Central controller
    reg [1:0] central_state; //Central state machine register
    typedef enum bit[1:0] {IDLE, FETCH_REQ, TAG_REPLACE, SYNC_RST} central_states;

    wire cache_miss = ({tag_valid[input_index], tag_buffer} != {1'b1, input_tag});

    wire fetch_request = (central_state == 1); //Request signal to the fetch state machine
    assign busy = (central_state != IDLE) || ((central_state == IDLE) && cache_miss); //Busy if central state isn't on idle mode
    
    wire [LINEADDR-1:0] invalid_index = invalidate_address[LINEADDR+OFFSADDR-1:OFFSADDR];

    always_ff @(posedge clk) begin : CentralStateMachine
        if(clk_en) begin
            case(central_state)
            IDLE: begin
                if(sync_rst) central_state <= SYNC_RST; //If sync_rst is active, trigger the SYNC_RST protocol
                else if(cache_miss) central_state <= FETCH_REQ; //If there's a cache miss, start the handling protocol
                if(invalidate) tag_valid[invalid_index] <= 0; //Invalidation process to mantain coherency
                end
            FETCH_REQ: begin //Send a signal to activate the fetch state machine
                central_state <= TAG_REPLACE;
                end
            TAG_REPLACE: begin
                if(fetch_transfer_finished) central_state <= IDLE;
                tag[input_index] <= input_tag; //Replace the tag
                tag_valid[input_index] <= 1; //Validate the tag
                end
            SYNC_RST: begin
                tag_valid <= 0; //Invalidate all tags
                central_state <= IDLE; //Go back to the idle state
                end
            endcase
        end
    end

    //Fetch controller
    reg [1:0] fetch_state; //Fetch state machine register
    typedef enum bit[1:0] {F_IDLE, F_SETUP, F_WAIT, F_TRANSFER} fetch_states;
    wire fetch_transfer_finished = (fetch_state == F_IDLE); //Notify the central controler when the fetching phase has finished

    reg [OFFSADDR-1:0] fetch_offset_pointer;
    reg [LATENCY_CTR_SIZE-1:0] stall_timer;

    always_ff @(posedge clk) begin : FetchStateMachine
        if(clk_en) begin
            case(fetch_state)
            F_IDLE: begin
                if(fetch_request) fetch_state <= F_SETUP;
                end
            F_SETUP: begin
                fetch_offset_pointer <= 0; //Reset the offset pointer (just in case)
                stall_timer <= 0; //Reset the stall timer (just in case)
                fetch_state <= F_WAIT; //Next state
                end
            F_WAIT: begin
                if(stall_timer == EXT_MEMORY_LATENCY-1) begin //After waiting for EXT_MEMORY_LATENCY cycles:
                    stall_timer <= 0; //Reset the stall timer
                    fetch_state <= F_TRANSFER; //Go to the F_TRANSFER phase
                end else stall_timer <= stall_timer + 1; //Else, increment the stall timer
                end
            F_TRANSFER: begin
                fetch_offset_pointer <= fetch_offset_pointer + 1; //Increment the offset pointer
                cache[input_index][fetch_offset_pointer] <= data_in; //Store the received data
                if(fetch_offset_pointer == OFFSADDR'(LINESIZE-1)) fetch_state <= F_IDLE; //If the whole line was fetched and stored, finish the protocol
                else fetch_state <= F_WAIT; //Else, repeat the process for each word until the whole line was fetched
                end
            endcase
        end
    end

endmodule : icache
