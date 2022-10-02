module oled(
input                   sys_clk             ,
input                   sys_rst_n           ,
input                   iic_driver_clk      ,

input                   oled_cmd            ,

input                   iic_done            ,
output reg              iic_exec            ,  
output reg              iic_w_ctrl          ,
output reg [7:0]        iic_w_data
);

/*----------------------------iic done fall edge---------------------------------*/

//generate a flag bit for the iic_done falling edge
reg  iic_done_cur;
reg  iic_done_per;
wire iic_done_trg;
//wire iic_done_trg;
assign iic_done_trg = (iic_done_per) & (~iic_done_cur);
always @(posedge iic_driver_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)begin
        iic_done_cur <= 1'b0;
        iic_done_per <= 1'b0;
        end
    else begin
        iic_done_cur <= iic_done;
        iic_done_per <= iic_done_cur;
        end
end

/*------------------------------------------------------------------------------*/
reg        oled_cmd_flag;

//bytes for oled init
reg [7:0]  Init_Command[22:0];
//bytes for oled set cursor
reg [7:0]  Cursor_Command[2:0];
//bytes for oled write data
reg [7:0]  Data_Command[127:0];


reg [5:0] oled_writecmd_cnt;    //Init_Command          0~22
reg [3:0] oled_setcursor_Y_cnt; //y 64/8                0~8
reg [7:0] oled_setcursor_X_cnt; //x 128                 0~128
reg [7:0] oled_writedata_cnt;   //data for each line    0~128

//FSM all states
localparam oled_st_idle       =  5'b00001;
localparam oled_st_writecmd   =  5'b00010;
localparam oled_st_setcursor  =  5'b00100;
localparam oled_st_writedata  =  5'b01000;
localparam oled_st_stop       =  5'b10000;
//reg for save state
reg [4:0] oled_cur_state; 
reg [4:0] oled_next_state;
//flag for state transfer
reg         oled_writecmd_flag;
reg         oled_setcursor_flag;
reg         oled_writedata_flag;
reg         oled_stop_flag;

initial oled_cmd_flag = 1'b1;

initial begin
    Init_Command[0 ] = 8'hAE;
    Init_Command[1 ] = 8'hD5;
    Init_Command[2 ] = 8'h80;
    Init_Command[3 ] = 8'hA8;
    Init_Command[4 ] = 8'h3F;
    Init_Command[5 ] = 8'hD3;
    Init_Command[6 ] = 8'h00;
    Init_Command[7 ] = 8'h40;
    Init_Command[8 ] = 8'hA1;
    Init_Command[9 ] = 8'hC8;
    Init_Command[10] = 8'hDA;
    Init_Command[11] = 8'h12;
    Init_Command[12] = 8'h81;
    Init_Command[13] = 8'hCF;
    Init_Command[14] = 8'hD9;
    Init_Command[15] = 8'hF1;
    Init_Command[16] = 8'hDB;
    Init_Command[17] = 8'h30;
    Init_Command[18] = 8'hA4;
    Init_Command[19] = 8'hA6;
    Init_Command[20] = 8'h8D;
    Init_Command[21] = 8'h14;
    Init_Command[22] = 8'hAF; 
    
    Cursor_Command[0] = 8'hB0;
    Cursor_Command[1] = 8'h10;
    Cursor_Command[2] = 8'h00;
    
    Data_Command[0  ] = 8'hf0;
    Data_Command[1  ] = 8'hf0;
    Data_Command[2  ] = 8'hf0;
    Data_Command[3  ] = 8'hf0;
    Data_Command[4  ] = 8'h0f;
    Data_Command[5  ] = 8'h0f;
    Data_Command[6  ] = 8'h0f;
    Data_Command[7  ] = 8'h0f;
    Data_Command[8  ] = 8'hf0;
    Data_Command[9  ] = 8'hf0;
    Data_Command[10 ] = 8'hf0;
    Data_Command[11 ] = 8'hf0;
    Data_Command[12 ] = 8'h0f;
    Data_Command[13 ] = 8'h0f;
    Data_Command[14 ] = 8'h0f;
    Data_Command[15 ] = 8'h0f;
    Data_Command[16 ] = 8'hf0;
    Data_Command[17 ] = 8'hf0;
    Data_Command[18 ] = 8'hf0;
    Data_Command[19 ] = 8'hf0;
    Data_Command[20 ] = 8'h0f;
    Data_Command[21 ] = 8'h0f;
    Data_Command[22 ] = 8'h0f;
    Data_Command[23 ] = 8'h0f;
    Data_Command[24 ] = 8'hf0;
    Data_Command[25 ] = 8'hf0;
    Data_Command[26 ] = 8'hf0;
    Data_Command[27 ] = 8'hf0;
    Data_Command[28 ] = 8'h0f;
    Data_Command[29 ] = 8'h0f;
    Data_Command[30 ] = 8'h0f;
    Data_Command[31 ] = 8'h0f;
    Data_Command[32 ] = 8'hf0;
    Data_Command[33 ] = 8'hf0;
    Data_Command[34 ] = 8'hf0;
    Data_Command[35 ] = 8'hf0;
    Data_Command[36 ] = 8'h0f;
    Data_Command[37 ] = 8'h0f;
    Data_Command[38 ] = 8'h0f;
    Data_Command[39 ] = 8'h0f;
    Data_Command[40 ] = 8'hf0;
    Data_Command[41 ] = 8'hf0;
    Data_Command[42 ] = 8'hf0;
    Data_Command[43 ] = 8'hf0;
    Data_Command[44 ] = 8'h0f;
    Data_Command[45 ] = 8'h0f;
    Data_Command[46 ] = 8'h0f;
    Data_Command[47 ] = 8'h0f;
    Data_Command[48 ] = 8'hf0;
    Data_Command[49 ] = 8'hf0;
    Data_Command[50 ] = 8'hf0;
    Data_Command[51 ] = 8'hf0;
    Data_Command[52 ] = 8'h0f;
    Data_Command[53 ] = 8'h0f;
    Data_Command[54 ] = 8'h0f;
    Data_Command[55 ] = 8'h0f;
    Data_Command[56 ] = 8'hf0;
    Data_Command[57 ] = 8'hf0;
    Data_Command[58 ] = 8'hf0;
    Data_Command[59 ] = 8'hf0;
    Data_Command[60 ] = 8'h0f;
    Data_Command[61 ] = 8'h0f;
    Data_Command[62 ] = 8'h0f;
    Data_Command[63 ] = 8'h0f;
    Data_Command[64 ] = 8'hf0;
    Data_Command[65 ] = 8'hf0;
    Data_Command[66 ] = 8'hf0;
    Data_Command[67 ] = 8'hf0;
    Data_Command[68 ] = 8'h0f;
    Data_Command[69 ] = 8'h0f;
    Data_Command[70 ] = 8'h0f;
    Data_Command[71 ] = 8'h0f;
    Data_Command[72 ] = 8'hf0;
    Data_Command[73 ] = 8'hf0;
    Data_Command[74 ] = 8'hf0;
    Data_Command[75 ] = 8'hf0;
    Data_Command[76 ] = 8'h0f;
    Data_Command[77 ] = 8'h0f;
    Data_Command[78 ] = 8'h0f;
    Data_Command[79 ] = 8'h0f;
    Data_Command[80 ] = 8'hf0;
    Data_Command[81 ] = 8'hf0;
    Data_Command[82 ] = 8'hf0;
    Data_Command[83 ] = 8'hf0;
    Data_Command[84 ] = 8'h0f;
    Data_Command[85 ] = 8'h0f;
    Data_Command[86 ] = 8'h0f;
    Data_Command[87 ] = 8'h0f;
    Data_Command[88 ] = 8'hf0;
    Data_Command[89 ] = 8'hf0;
    Data_Command[90 ] = 8'hf0;
    Data_Command[91 ] = 8'hf0;
    Data_Command[92 ] = 8'h0f;
    Data_Command[93 ] = 8'h0f;
    Data_Command[94 ] = 8'h0f;
    Data_Command[95 ] = 8'h0f;
    Data_Command[96 ] = 8'hf0;
    Data_Command[97 ] = 8'hf0;
    Data_Command[98 ] = 8'hf0;
    Data_Command[99 ] = 8'hf0;
    Data_Command[100] = 8'h0f;
    Data_Command[101] = 8'h0f;
    Data_Command[102] = 8'h0f;
    Data_Command[103] = 8'h0f;
    Data_Command[104] = 8'hf0;
    Data_Command[105] = 8'hf0;
    Data_Command[106] = 8'hf0;
    Data_Command[107] = 8'hf0;
    Data_Command[108] = 8'h0f;
    Data_Command[109] = 8'h0f;
    Data_Command[110] = 8'h0f;
    Data_Command[111] = 8'h0f;
    Data_Command[112] = 8'hf0;
    Data_Command[113] = 8'hf0;
    Data_Command[114] = 8'hf0;
    Data_Command[115] = 8'hf0;
    Data_Command[116] = 8'h0f;
    Data_Command[117] = 8'h0f;
    Data_Command[118] = 8'h0f;
    Data_Command[119] = 8'h0f;
    Data_Command[120] = 8'hf0;
    Data_Command[121] = 8'hf0;
    Data_Command[122] = 8'hf0;
    Data_Command[123] = 8'hf0;
    Data_Command[124] = 8'h0f;
    Data_Command[125] = 8'h0f;
    Data_Command[126] = 8'h0f;
    Data_Command[127] = 8'h0f;
    Data_Command[128] = 8'h0f;
end

//State
always @(posedge iic_driver_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        oled_cur_state <= oled_st_idle;
    else
        oled_cur_state <= oled_next_state;
end
//Event
always @(*) begin
    oled_next_state = oled_st_idle;
    case(oled_cur_state)
        oled_st_idle      :
            oled_next_state = oled_writecmd_flag  ? oled_st_writecmd : oled_st_idle;
        oled_st_writecmd  :
            oled_next_state = oled_setcursor_flag ? oled_st_setcursor : oled_st_writecmd;
        oled_st_setcursor :
            oled_next_state = oled_writedata_flag ? oled_st_writedata : oled_st_setcursor;
        oled_st_writedata :
            oled_next_state = oled_stop_flag ? oled_st_stop :(oled_setcursor_flag ? oled_st_setcursor : oled_st_writedata);
        oled_st_stop      :;
    endcase
end
//Action
always @(posedge iic_driver_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        begin
            oled_cmd_flag      <= 1'b1;
            
            iic_exec           <= 1'b0;
            iic_w_ctrl         <= 1'b1;
            iic_w_data         <= 8'b0;

            oled_writecmd_cnt  <= 5'd0;
            oled_writedata_cnt <= 8'd0;
            oled_setcursor_Y_cnt <= 4'd0;
            oled_setcursor_X_cnt <= 8'd0;
            
            oled_writecmd_flag  <= 1'b0;
            oled_writedata_flag <= 1'b0;
            oled_setcursor_flag <= 1'b0;
            oled_stop_flag      <= 1'b0;
        end
    else
        begin
            case(oled_cur_state)
                oled_st_idle      :begin
                    iic_exec    <= 1'b0;
                    iic_w_ctrl  <= 1'b1;
                    iic_w_data  <= 8'b0;
                    if(oled_cmd_flag) begin
                        oled_writecmd_cnt  <= 5'd0;
                        oled_writecmd_flag <= 1'b1;
                        end
                    else
                        oled_writecmd_flag <= 1'b0;
                end
                oled_st_writecmd  :begin
                    if(iic_done)begin
                        iic_exec    <= 1'b1;
                        iic_w_ctrl  <= 1'b1;
                        iic_w_data  <= Init_Command[oled_writecmd_cnt];
                        end
                    else
                        iic_exec    <= 1'b0;

                    if(oled_writecmd_cnt == 5'd23)
                        oled_setcursor_flag <= 1'b1;
                    else begin
                        oled_setcursor_flag <= 1'b0;
                        if(iic_done_trg)
                            oled_writecmd_cnt <= oled_writecmd_cnt + 1'b1;
                        else
                            oled_writecmd_cnt <= oled_writecmd_cnt;
                        end
                end
                
                oled_st_setcursor :begin
                    oled_writecmd_flag  <= 1'b0;
                    oled_writedata_flag <= 1'b0;
                    if(iic_done)begin
                        iic_exec    <= 1'b1;
                        iic_w_ctrl  <= 1'b1;
                        iic_w_data  <= (Cursor_Command[0]|oled_setcursor_Y_cnt);
                        end
                    else
                        iic_exec    <= 1'b0;

                    if(oled_setcursor_Y_cnt == 4'd9)
                        begin
                            oled_stop_flag <= 1'b1;
                            oled_setcursor_Y_cnt <= 4'd0;
                        end
                    else if(iic_done_trg)begin
                            oled_setcursor_Y_cnt <= oled_setcursor_Y_cnt + 1'b1;
                            oled_writedata_cnt  <= 8'd0;
                            oled_writedata_flag <= 1'b1;
                            oled_setcursor_flag <= 1'b0;
                            end
                        else
                            oled_setcursor_Y_cnt <= oled_setcursor_Y_cnt;
                end
                
                oled_st_writedata :begin
                    oled_setcursor_flag <= 1'b0;
                    if(iic_done)begin
                        iic_exec    <= 1'b1;
                        iic_w_ctrl  <= 1'b0;
                        if(oled_setcursor_Y_cnt%2)
                            iic_w_data  <=  Data_Command[oled_writedata_cnt];
                        else
                            iic_w_data  <= ~Data_Command[oled_writedata_cnt];
                        end
                    else
                        iic_exec    <= 1'b0;

                    if(oled_writedata_cnt == 8'd128)
                        oled_setcursor_flag <= 1'b1;

                    else begin
                        oled_setcursor_flag <= 1'b0;
                        if(iic_done_trg)
                            oled_writedata_cnt <= oled_writedata_cnt + 1'b1;
                        else
                            oled_writedata_cnt <= oled_writedata_cnt;
                        end                
                    end

                oled_st_stop      :begin
                    oled_writecmd_flag   <= 1'b0;
                    oled_setcursor_flag  <= 1'b0;
                    oled_writedata_flag  <= 1'b0; 
                    oled_cmd_flag        <= 1'b0;
                end
            endcase
        end
end

endmodule