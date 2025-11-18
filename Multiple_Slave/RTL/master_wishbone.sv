module master_wishbone #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int SEL_WIDTH  = DATA_WIDTH/8
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic [ADDR_WIDTH-1:0] addr_input,
    output logic [ADDR_WIDTH-1:0] addr_o,

    input  logic [DATA_WIDTH-1:0] data_input,
    output logic [DATA_WIDTH-1:0] data_o,

    input  logic write_enable,
    output logic we_o,

    input  logic [SEL_WIDTH-1:0] sel_input,
    output logic [SEL_WIDTH-1:0] sel_o,

    input  logic [1:0] strobe,
    output logic [1:0] stb_o,

    input  logic cyc_input,
    output logic cyc_o,
    
    input logic [2:0] cti_input,
    output logic [2:0] cti_o,
    
    input logic tag_add_i,
    output logic tag_add_out2s,


    input  logic [DATA_WIDTH-1:0] data_i,
    output logic [DATA_WIDTH-1:0] data_received,

    input  logic ack_i,
    output logic acknowledgement,
    
    input logic err_i,
    output logic error,
    
    output logic [1:0] state_out  
);
  
typedef enum logic [1:0] {
    IDLE,
    BUS_REQUEST,
    BUS_WAIT
} wishbone_state;

wishbone_state state, next_state;

assign state_out = state;

logic [ADDR_WIDTH-1:0] addr_reg;
logic [DATA_WIDTH-1:0] data_reg;
logic we_reg;
logic [SEL_WIDTH-1:0] sel_reg;
logic [1:0] stb_reg;
logic cyc_reg;
logic [DATA_WIDTH-1:0] data_received_reg;
logic ack_reg;
logic [2:0] cti_reg;
logic err_reg;
logic tag_add_reg;

assign addr_o = addr_reg;
assign data_o = data_reg;
assign we_o = we_reg;
assign sel_o = sel_reg;
assign stb_o = stb_reg;
assign cyc_o = cyc_reg;
assign cti_o = cti_reg;
assign tag_add_out2s = tag_add_reg;

assign data_received = data_received_reg;
assign acknowledgement = ack_reg;
assign error = err_reg;
 
always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
        state <= IDLE;
    else
        state <= next_state;
end
  
always_comb begin
    case (state) 
        IDLE : begin
            if(cyc_input & (strobe[1] | strobe[0])) 
                next_state = BUS_REQUEST;
            else 
                next_state = IDLE;
        end

        BUS_REQUEST : begin
            if(cyc_input & !(strobe[1] | strobe[0]) & (((cti_input[2:0] == 3'b001)) | ((cti_input[2:0] == 3'b010))) & (ack_reg|err_reg)) 
                next_state = BUS_WAIT;
            else if (!cyc_input & !(strobe[1] | strobe[0]) & ((cti_input[2:0] == 3'b000)) & (ack_reg|err_reg))
                next_state = IDLE;
            else 
                next_state = BUS_REQUEST;
        end

        BUS_WAIT : begin
            if(cyc_input & (strobe[1] | strobe[0]) & (((cti_input[2:0] == 3'b001)) | ((cti_input[2:0] == 3'b010)))) 
                next_state = BUS_REQUEST;
            else if(!cyc_input & !(strobe[1] | strobe[0]) & (cti_input[2:0] == 3'b111)) 
                next_state = IDLE;
            else 
                next_state = BUS_WAIT; 
        end

        default : next_state = IDLE;
    endcase
end

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        addr_reg <= {ADDR_WIDTH{1'b0}};
        data_reg <= {DATA_WIDTH{1'b0}};
        we_reg <= 1'b0;
        sel_reg <= {SEL_WIDTH{1'b0}};
        stb_reg <= 2'b0;
        cyc_reg <= 1'b0;
        tag_add_reg <= 1'b0;
        data_received_reg <= {DATA_WIDTH{1'b0}};
        ack_reg <= 1'b0;
        cti_reg <= 3'b000;
        err_reg <= 1'b0;
    end else begin
        case (next_state)  
            IDLE: begin
                addr_reg <= {ADDR_WIDTH{1'b0}};
                data_reg <= {DATA_WIDTH{1'b0}};
                we_reg <= 1'b0;
                sel_reg <= {SEL_WIDTH{1'b0}};
                stb_reg <= 2'b0;
                cyc_reg <= 1'b0;
                ack_reg <= 1'b0;
                data_received_reg <= {DATA_WIDTH{1'b0}};
                tag_add_reg <= 1'b0;
                cti_reg <= 3'b000;
                err_reg <= 1'b0;
            end

            BUS_REQUEST: begin
                addr_reg <= addr_input;
                sel_reg <= sel_input;
                we_reg  <= write_enable; 
                stb_reg <= strobe;
                cyc_reg <= cyc_input;
                ack_reg <= ack_i; 
                err_reg <= err_i;
                cti_reg <= cti_input;
                tag_add_reg <= tag_add_i;
                if (write_enable) 
                    data_reg <= data_input;
                else if (!write_enable)
                    data_received_reg <= data_i;                    
            end

            BUS_WAIT: begin
                addr_reg <= {ADDR_WIDTH{1'b0}};
                data_reg <= {DATA_WIDTH{1'b0}};
                sel_reg <= {SEL_WIDTH{1'b0}};
                data_received_reg <= {DATA_WIDTH{1'b0}};
                stb_reg <= 2'b0;
                cyc_reg <= cyc_input;  
                we_reg <= we_reg;
                tag_add_reg <= 1'b0;
                ack_reg <= 1'b0;
                cti_reg <= 3'b000;
                err_reg <= 1'b0;
            end

        endcase
    end
end

endmodule
