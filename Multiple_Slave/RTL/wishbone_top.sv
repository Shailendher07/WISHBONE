`timescale 1ns / 1ps
module wishbone_top #(
  parameter int ADDR_WIDTH = 4,
  parameter int DATA_WIDTH = 32,
  parameter int SEL_WIDTH  = DATA_WIDTH/8
)(
  input  logic clk_i,
  input  logic rst_i,

  input  logic [ADDR_WIDTH-1:0] addr_o,
  input  logic [DATA_WIDTH-1:0] data_o,
  input  logic we_o,
  input  logic [1:0] stb_o,
  input  logic cyc_o,
  input  logic [SEL_WIDTH-1:0] sel_o,
  input  logic [2:0] cti_input,
  input logic tag_add,

  output logic ack_i,
  output logic err_i,
  output logic [DATA_WIDTH-1:0] data_i,
  output logic [1:0] state_out,

  output logic [ADDR_WIDTH-1:0] dbg_w_addr,
  output logic [DATA_WIDTH-1:0] dbg_w_data_m2s,
  output logic [DATA_WIDTH-1:0] dbg_w_data_s2m,
  output logic [ADDR_WIDTH-1:0] counter,
  output logic dbg_w_we,
  output logic dbg_tag_add,
  output logic [SEL_WIDTH-1:0] dbg_w_sel,
  output logic [1:0] dbg_w_stb,
  output logic dbg_w_cyc,
  output logic dbg_w_ack,
  output logic dbg_w_err,
  output logic [2:0] dbg_cti
);

 
  logic [ADDR_WIDTH-1:0] w_addr;
  logic [DATA_WIDTH-1:0] w_data_m2s;
  logic [DATA_WIDTH-1:0] w_data_s2m; 
  logic w_we;
  logic [SEL_WIDTH-1:0] w_sel;
  logic [1:0] w_stb;
  logic w_cyc;
  logic tag_addd;
  logic w_ack; 
  logic w_err; 
  logic [2:0] cti;


  logic w_ack_s1, w_ack_s2;
  logic w_err_s1, w_err_s2;
  logic [DATA_WIDTH-1:0] w_data_s2m_s1, w_data_s2m_s2;
  logic [ADDR_WIDTH-1:0] counter_s1, counter_s2;

  assign dbg_w_addr = w_addr;
  assign dbg_w_data_m2s = w_data_m2s;
  assign dbg_w_we = w_we;
  assign dbg_w_sel = w_sel;
  assign dbg_w_stb = w_stb;
  assign dbg_w_cyc = w_cyc;
  assign dbg_cti = cti;
  assign dbg_tag_add = tag_addd;

  assign w_ack = w_ack_s1 | w_ack_s2;
  assign w_err = w_err_s1 | w_err_s2;
  assign dbg_w_ack = w_ack;
  assign dbg_w_err = w_err;


  assign w_data_s2m = (w_data_s2m_s1 | w_data_s2m_s2 );
  assign dbg_w_data_s2m = w_data_s2m;

  assign counter = (w_stb[1]) ? counter_s1 :
                   (w_stb[0]) ? counter_s2 :
                               {ADDR_WIDTH{1'b0}};


  master_wishbone #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SEL_WIDTH(SEL_WIDTH)
  ) m1 (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .addr_input(addr_o),
    .addr_o(w_addr),
    .data_input(data_o),
    .data_o(w_data_m2s),
    .write_enable(we_o),
    .we_o(w_we),
    .sel_input(sel_o),
    .sel_o(w_sel),
    .strobe(stb_o),
    .stb_o(w_stb),
    .cyc_input(cyc_o),
    .cyc_o(w_cyc),
    .cti_input(cti_input),
    .cti_o(cti),
    .tag_add_i(tag_add),
    .tag_add_out2s(tag_addd),
    .data_i(w_data_s2m),
    .data_received(data_i),
    .ack_i(w_ack),
    .acknowledgement(ack_i),
    .err_i(w_err),
    .error(err_i),
    .state_out(state_out)
  );

  slave_wishbone #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SEL_WIDTH(SEL_WIDTH)
  ) s1 (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .addr_i(w_addr),
    .data_i(w_data_m2s),
    .we_i(w_we),
    .sel_i(w_sel),
    .stb_i(w_stb[1]),
    .cyc_i(w_cyc),
    .cti_i(cti),
    .tag_add_i(tag_addd),
    .ack_o(w_ack_s1),
    .err_o(w_err_s1),
    .data_o(w_data_s2m_s1),
    .counter_out(counter_s1)
  );


  slave_wishbone #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .SEL_WIDTH(SEL_WIDTH)
  ) s2 (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .addr_i(w_addr),
    .data_i(w_data_m2s),
    .we_i(w_we),
    .sel_i(w_sel),
    .stb_i(w_stb[0]),
    .cyc_i(w_cyc),
    .cti_i(cti),
    .tag_add_i(tag_addd),
    .ack_o(w_ack_s2),
    .err_o(w_err_s2),
    .data_o(w_data_s2m_s2),
    .counter_out(counter_s2)
  );

endmodule
