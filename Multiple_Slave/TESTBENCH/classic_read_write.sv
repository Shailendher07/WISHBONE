`timescale 1ns / 1ps

module tb;

  parameter ADDR_WIDTH = 4;
  parameter DATA_WIDTH = 32;
  parameter SEL_WIDTH  = DATA_WIDTH/8;

  logic clk_i, rst_i;
  logic [ADDR_WIDTH-1:0] addr_o;
  logic [DATA_WIDTH-1:0] data_o;
  logic we_o;
  logic [1:0] stb_o;
  logic cyc_o;
  logic [SEL_WIDTH-1:0] sel_o;
  logic [2:0] cti_input;
  logic tag_add;

  logic ack_i;
  logic err_i;
  logic [DATA_WIDTH-1:0] data_i;
  logic [1:0] state_out;

  logic [ADDR_WIDTH-1:0] dbg_w_addr;
  logic [DATA_WIDTH-1:0] dbg_w_data_m2s;
  logic [DATA_WIDTH-1:0] dbg_w_data_s2m;
  logic [ADDR_WIDTH-1:0] counter;
  logic dbg_w_we;
  logic dbg_tag_add;
  logic [SEL_WIDTH-1:0] dbg_w_sel;
  logic [1:0] dbg_w_stb;
  logic dbg_w_cyc;
  logic dbg_w_ack;
  logic dbg_w_err;
  logic [2:0] dbg_cti;

  wishbone_top dut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .addr_o(addr_o),
    .data_o(data_o),
    .we_o(we_o),
    .stb_o(stb_o),
    .cyc_o(cyc_o),
    .sel_o(sel_o),
    .cti_input(cti_input),
    .tag_add(tag_add),

    .ack_i(ack_i),
    .err_i(err_i),
    .data_i(data_i),
    .state_out(state_out),

    .dbg_w_addr(dbg_w_addr),
    .dbg_w_data_m2s(dbg_w_data_m2s),
    .dbg_w_data_s2m(dbg_w_data_s2m),
    .counter(counter),
    .dbg_w_we(dbg_w_we),
    .dbg_tag_add(dbg_tag_add),
    .dbg_w_sel(dbg_w_sel),
    .dbg_w_stb(dbg_w_stb),
    .dbg_w_cyc(dbg_w_cyc),
    .dbg_w_ack(dbg_w_ack),
    .dbg_w_err(dbg_w_err),
    .dbg_cti(dbg_cti)
  );

    initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  initial begin
    rst_i = 1;
    addr_o = 0;
    data_o = 0;
    we_o = 0;
    stb_o = 2'b0;
    cyc_o = 0;
    tag_add = 0;
    sel_o = 4'hf;
    cti_input = 3'b000;
    tag_add = 0;
    #20 rst_i = 0;
  end

  task single_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
      @(negedge clk_i);
      addr_o = addr;
      data_o = data;
      we_o = 1;
      stb_o[1] = 1;
      cyc_o = 1;
      #10;
      @(negedge clk_i);
      stb_o[1] = 0;
      cyc_o = 0;
      we_o = 0;
      #30;
    end
  endtask
  
  task single_writee(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
      @(negedge clk_i);
      addr_o = addr;
      data_o = data;
      we_o = 1;
      stb_o[0] = 1;
      cyc_o = 1;
      #10;
      @(negedge clk_i);
      stb_o[0] = 0;
      cyc_o = 0;
      we_o = 0;
      #30;
    end
  endtask
  
  
  task tag_add_readd(input [1:0] stb_val);
    begin
      @(negedge clk_i);
      addr_o = 5'd2;
      data_o = 0;
      we_o = 0;
      stb_o = stb_val;  
      cyc_o = 1;
      tag_add = 1;
      #10;
      @(negedge clk_i);
      stb_o = 2'b00;
      tag_add = 0;
      #30;
      cti_input = 3'b000;
      cyc_o = 0;
    end
  endtask  

  initial begin
    @(negedge rst_i);
    #20;

    single_write(4'd0, 32'h0000_1111);
    single_write(4'd1, 32'h0000_2222);
    single_write(4'd9, 32'h0000_2222);
    tag_add_readd(2'b10);
    cti_input = 3'b000;
    single_writee(4'd0, 32'h11110000);
    single_writee(4'd1, 32'h0000_1111);
    tag_add_readd(2'b01);
    #50;
    $finish;
  end

endmodule
