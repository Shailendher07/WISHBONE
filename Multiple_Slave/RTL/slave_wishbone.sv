module slave_wishbone #(
parameter int ADDR_WIDTH = 4,
parameter int DATA_WIDTH = 32,
parameter int SEL_WIDTH  = DATA_WIDTH/8
)(
input  logic rst_i,
input  logic clk_i,
input  logic [ADDR_WIDTH-1:0] addr_i,
input  logic [DATA_WIDTH-1:0] data_i,
input  logic we_i,
input  logic [SEL_WIDTH-1:0] sel_i,
input  logic stb_i,
input  logic cyc_i,
input  logic [2:0] cti_i,
input logic tag_add_i,

output logic ack_o,
output logic err_o,
output logic [DATA_WIDTH-1:0] data_o,
output logic [ADDR_WIDTH-1:0] counter_out
);

logic [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1] = '{default: '0};
logic [ADDR_WIDTH-1:0] counter = {ADDR_WIDTH{1'b0}};

assign counter_out = counter;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        ack_o   <= 1'b0;
        err_o   <= 1'b0;
        data_o  <= {DATA_WIDTH{1'b0}};
        counter <= {ADDR_WIDTH{1'b0}};
    
    end 
    else begin
        if (stb_i & cyc_i & we_i) begin
        
            if (cti_i == 3'b001 | cti_i == 3'b000) begin
                if ((addr_i + counter) > 8) begin
                err_o <= 1'b1;
                ack_o <= 1'b0;
                end             
                else begin
                    for (int i = 0; i < SEL_WIDTH; i++) begin
                        if (sel_i[i] == 1'b1) begin
                            mem[addr_i][(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)] <= data_i[(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)];
                        end
                    end
                ack_o <= ( stb_i & cyc_i) ;
                err_o <= 1'b0;
                data_o <= {DATA_WIDTH{1'b0}};
                end 
            end
            
            else if (cti_i == 3'b010) begin
                if ((addr_i + counter) > 8) begin
                err_o <= 1'b1;
                ack_o <= 1'b0;
                counter <= counter + 1;
                end 
                else begin
                    counter <= counter + 1;
                    for (int i = 0; i < SEL_WIDTH; i++) begin
                        if (sel_i[i] == 1'b1) begin
                            mem[addr_i + counter][(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)] <= data_i[(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)];
                        end
                    end
                    ack_o <= ( stb_i & cyc_i) ;
                    err_o <= 1'b0;
                    data_o <= {DATA_WIDTH{1'b0}};
                end
            end
        end 
        
        else if (stb_i & cyc_i & !we_i) begin
        
            if(tag_add_i) begin
                ack_o <= ( stb_i & cyc_i) ;
                err_o <= 1'b0;
                data_o <= mem[0] + mem[1];
            end
        
            else if (cti_i == 3'b001 | cti_i == 3'b000) begin
                if ((addr_i + counter) > 8) begin
                err_o <= 1'b1;
                ack_o <= 1'b0;
                end             
                else begin
                data_o <= {DATA_WIDTH{1'b0}};
                    for (int i = 0; i < SEL_WIDTH; i++) begin
                        if (sel_i[i] == 1'b1) begin
                        data_o[(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)] <= mem[addr_i][(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)];                         
                        end
                    end
                ack_o <= ( stb_i & cyc_i) ;
                err_o <= 1'b0;
                end 
            end 
            
            else if (cti_i == 3'b010) begin
                if ((addr_i + counter) > 8) begin
                    err_o <= 1'b1;
                    ack_o <= 1'b0;   
                    data_o <= {DATA_WIDTH{1'b0}};
                    counter <= counter + 1;
                end 
                else begin
                    counter <= counter + 1;
                    for (int i = 0; i < SEL_WIDTH; i++) begin
                            if (sel_i[i]) begin
                                data_o[(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)] <= mem[addr_i + counter][(i+1)*(DATA_WIDTH/SEL_WIDTH)-1 -: (DATA_WIDTH/SEL_WIDTH)];
                            end
                    end
                    ack_o <= ( stb_i & cyc_i) ;
                    err_o <= 1'b0;                
                end
            end 
        end
        
            
        else begin
            ack_o <= 1'b0;
            err_o <= 1'b0;                
            data_o <= {DATA_WIDTH{1'b0}};
        end
    end
end


endmodule
