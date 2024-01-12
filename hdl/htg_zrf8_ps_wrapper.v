//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
//Date        : Thu Jan 11 11:25:54 2024
//Host        : ASCPHY-NC196428 running 64-bit major release  (build 9200)
//Command     : generate_target htg_zrf8_ps_wrapper.bd
//Design      : htg_zrf8_ps_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module htg_zrf8_ps_wrapper
   (Vp_Vn_v_n,
    Vp_Vn_v_p,
    adc0_clk_0_clk_n,
    adc0_clk_0_clk_p,
    clk_adc0_0,
    led_pl_tri_o,
    m00_axis_0_tdata,
    m00_axis_0_tready,
    m00_axis_0_tvalid,
    m0_axis_aclk_0,
    m0_axis_aresetn_0,
    pl_clk0,
    pl_resetn0,
    sysref_in_0_diff_n,
    sysref_in_0_diff_p,
    user_sysref_adc_0,
    vin0_01_0_v_n,
    vin0_01_0_v_p);
  input Vp_Vn_v_n;
  input Vp_Vn_v_p;
  input adc0_clk_0_clk_n;
  input adc0_clk_0_clk_p;
  output clk_adc0_0;
  output [2:0]led_pl_tri_o;
  output [127:0]m00_axis_0_tdata;
  input m00_axis_0_tready;
  output m00_axis_0_tvalid;
  input m0_axis_aclk_0;
  input m0_axis_aresetn_0;
  output pl_clk0;
  output pl_resetn0;
  input sysref_in_0_diff_n;
  input sysref_in_0_diff_p;
  input user_sysref_adc_0;
  input vin0_01_0_v_n;
  input vin0_01_0_v_p;

  wire Vp_Vn_v_n;
  wire Vp_Vn_v_p;
  wire adc0_clk_0_clk_n;
  wire adc0_clk_0_clk_p;
  wire clk_adc0_0;
  wire [2:0]led_pl_tri_o;
  wire [127:0]m00_axis_0_tdata;
  wire m00_axis_0_tready;
  wire m00_axis_0_tvalid;
  wire m0_axis_aclk_0;
  wire m0_axis_aresetn_0;
  wire pl_clk0;
  wire pl_resetn0;
  wire sysref_in_0_diff_n;
  wire sysref_in_0_diff_p;
  wire user_sysref_adc_0;
  wire vin0_01_0_v_n;
  wire vin0_01_0_v_p;

  htg_zrf8_ps htg_zrf8_ps_i
       (.Vp_Vn_v_n(Vp_Vn_v_n),
        .Vp_Vn_v_p(Vp_Vn_v_p),
        .adc0_clk_0_clk_n(adc0_clk_0_clk_n),
        .adc0_clk_0_clk_p(adc0_clk_0_clk_p),
        .clk_adc0_0(clk_adc0_0),
        .led_pl_tri_o(led_pl_tri_o),
        .m00_axis_0_tdata(m00_axis_0_tdata),
        .m00_axis_0_tready(m00_axis_0_tready),
        .m00_axis_0_tvalid(m00_axis_0_tvalid),
        .m0_axis_aclk_0(m0_axis_aclk_0),
        .m0_axis_aresetn_0(m0_axis_aresetn_0),
        .pl_clk0(pl_clk0),
        .pl_resetn0(pl_resetn0),
        .sysref_in_0_diff_n(sysref_in_0_diff_n),
        .sysref_in_0_diff_p(sysref_in_0_diff_p),
        .user_sysref_adc_0(user_sysref_adc_0),
        .vin0_01_0_v_n(vin0_01_0_v_n),
        .vin0_01_0_v_p(vin0_01_0_v_p));
endmodule
