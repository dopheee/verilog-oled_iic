`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/09/30 20:45:42
// Design Name: 
// Module Name: oled_iic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module oled_iic(
     input sys_clk,
     input sys_rst_n,

     output iic_sda,
     output iic_scl,
     output reg vcc,
     output reg gnd
    );

always @(*) begin
    vcc = 1'b1;
    gnd = 1'b0;
end

reg oled_cmd;

//reg sys_clk;
//reg sys_rst_n;
//wire iic_sda;
//wire iic_scl;
//always #10 sys_clk = ~sys_clk;
//initial begin
//    sys_clk = 1'b0;
//    sys_rst_n = 1'b0;
//    #200
//    sys_rst_n = 1'b1;
//end

initial oled_cmd = 1'b1;



wire iic_driver_clk;


wire iic_exec;
wire iic_done;
wire iic_w_ctrl;
wire [7:0] iic_w_data;

oled  u_oled (
   .sys_clk                 ( sys_clk               ),
   .sys_rst_n               ( sys_rst_n             ),
   .iic_driver_clk          ( iic_driver_clk        ),
   .oled_cmd                ( oled_cmd              ),
   .iic_done                ( iic_done              ),

   .iic_exec                ( iic_exec              ),
   .iic_w_ctrl              ( iic_w_ctrl            ),
   .iic_w_data              ( iic_w_data      [7:0] )
);
    
iic u_iic (
   .sys_clk                 ( sys_clk               ),
   .sys_rst_n               ( sys_rst_n             ),
   .iic_exec                ( iic_exec              ),
   .iic_w_ctrl              ( iic_w_ctrl            ),
   .iic_w_data              ( iic_w_data      [7:0] ),

   .iic_scl                 ( iic_scl               ),
   .iic_sda                 ( iic_sda               ),
   .iic_done                ( iic_done              ),
   .iic_driver_clk          ( iic_driver_clk        )
);
    
endmodule
