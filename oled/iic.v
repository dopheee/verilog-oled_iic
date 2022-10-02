module iic #(
    //绯荤粺鏃堕挓鍜孖IC鏃堕�?
    parameter SYS_CLK = 26'd50_000_000,
    parameter IIC_CLK = 19'd400_000,
    //IIC浠庢�?鍦板�?
    parameter SLAVE_ADDR = 7'b0111100
)
(
    input            sys_clk        ,
    input            sys_rst_n      ,
    
    input            iic_exec       ,
    input            iic_w_ctrl     ,    //1:command  0:data
    input      [7:0] iic_w_data     ,
    output reg       iic_scl        ,
    output reg       iic_sda        ,
    output reg       iic_done       ,
    output reg       iic_driver_clk
    
);


/*-------------------------------------iic_driver_clk---------------------------------------------------*/
reg   [9:0]  clk_count;
wire  [8:0]  clk_divide;

// iic_driver_clk = iic_clk * 4
assign clk_divide = (SYS_CLK/IIC_CLK)>>2'd2;
// creat iic driver_clk
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        begin
            iic_driver_clk <= 1'b0;
            clk_count <= 10'd0;
        end
    else
        if(clk_count == clk_divide - 9'd1)
            begin
                clk_count <= 10'd0;
                iic_driver_clk <= ~iic_driver_clk;
            end
        else
            clk_count <= clk_count + 10'd1;
end
/*-------------------------------------------------------------------------------------------------------*/



/********************************************   FSM  ****************************************************/

localparam iic_st_idle       = 6'b000001;
localparam iic_st_w_addr     = 6'b000010;
localparam iic_st_w_command  = 6'b000100;
localparam iic_st_w_data     = 6'b001000;
localparam iic_st_w_data_in  = 6'b010000;
localparam iic_st_stop       = 6'b100000;

reg [5:0] iic_cur_state;
reg [5:0] iic_next_state;
reg       iic_st_done;

//temp value for state output
reg [7:0] iic_temp_w_data;
reg       iic_temp_w_ctrl;
//cnt
reg [5:0] process_cnt;



//state transfer
always @(posedge iic_driver_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        iic_cur_state <= iic_st_idle;
    else
        iic_cur_state <= iic_next_state;
end

//determine iic_next_state based on iic_cur_state
always @(*) begin
    iic_next_state = iic_st_idle;
    case(iic_cur_state)
        iic_st_idle      :
            iic_next_state = iic_exec    ? iic_st_w_addr    : iic_st_idle;
        iic_st_w_addr    :
            iic_next_state = iic_st_done ? (iic_w_ctrl ? iic_st_w_command : iic_st_w_data) : iic_st_w_addr;
        iic_st_w_command :
            iic_next_state = iic_st_done ? iic_st_w_data_in : iic_st_w_command;
        iic_st_w_data    :
            iic_next_state = iic_st_done ? iic_st_w_data_in : iic_st_w_data;
        iic_st_w_data_in :
            iic_next_state = iic_st_done ? iic_st_stop      : iic_st_w_data_in;
        iic_st_stop      :
            iic_next_state = iic_st_done ? iic_st_idle      : iic_st_stop;
    endcase
end


//state output
always @(posedge iic_driver_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        begin
            iic_scl  <= 1'b1;
            iic_sda  <= 1'b1;
            iic_done <= 1'b1;
            iic_temp_w_data <= 8'b0;
            iic_temp_w_ctrl <= 1'b0;
            process_cnt <= 6'd0;
            iic_st_done <= 1'b0;
        end
    else
        begin
            iic_st_done <= 1'b0;
            process_cnt <= process_cnt + 6'd1;
            case(iic_cur_state)
                iic_st_idle      :begin
                    iic_scl  <= 1'b1;
                    iic_sda  <= 1'b1;
                    iic_done <= 1'b1;
                    process_cnt <= 6'd0;
                    if(iic_exec)begin
                        iic_temp_w_data <= iic_w_data;
                        iic_temp_w_ctrl <= iic_w_ctrl;
                        iic_done <= 1'b0;
                    end
                end
                //write 0x78 for oled
                iic_st_w_addr    :begin
                    case(process_cnt)
                        6'd1  :iic_sda <= 1'b0;
                        6'd3  :iic_scl <= 1'b0;
                        6'd4  :iic_sda <= SLAVE_ADDR[6];    //1
                        6'd5  :iic_scl <= 1'b1;
                        6'd7  :iic_scl <= 1'b0;
                        6'd8  :iic_sda <= SLAVE_ADDR[5];    //2
                        6'd9  :iic_scl <= 1'b1; 
                        6'd11 :iic_scl <= 1'b0;
                        6'd12 :iic_sda <= SLAVE_ADDR[4];    //3
                        6'd13 :iic_scl <= 1'b1;
                        6'd15 :iic_scl <= 1'b0;
                        6'd16 :iic_sda <= SLAVE_ADDR[3];    //4
                        6'd17 :iic_scl <= 1'b1;
                        6'd19 :iic_scl <= 1'b0;
                        6'd20 :iic_sda <= SLAVE_ADDR[2];    //5
                        6'd21 :iic_scl <= 1'b1;
                        6'd23 :iic_scl <= 1'b0;
                        6'd24 :iic_sda <= SLAVE_ADDR[1];    //6
                        6'd25 :iic_scl <= 1'b1;
                        6'd27 :iic_scl <= 1'b0;
                        6'd28 :iic_sda <= SLAVE_ADDR[0];    //7
                        6'd29 :iic_scl <= 1'b1;
                        6'd31 :iic_scl <= 1'b0;
                        6'd32 :iic_sda <= 1'b0;             //8     0:writedata
                        6'd33 :iic_scl <= 1'b1;
                        6'd35 :iic_scl <= 1'b0;
                        6'd37 :iic_scl <= 1'b1;             //ack
                        6'd38 :iic_st_done <= 1'b1;
                        6'd39 :begin
                                iic_scl <= 1'b0;
                                process_cnt <= 6'd0;
                        end
                        default :;
                    endcase
                end
                //write 0x00 -> write command
                iic_st_w_command :begin
                    case(process_cnt)
                        6'd0  :iic_sda <= 1'b0;             //1
                        6'd1  :iic_scl <= 1'b1;
                        6'd3  :iic_scl <= 1'b0;
                        6'd4  :iic_sda <= 1'b0;             //2
                        6'd5  :iic_scl <= 1'b1;
                        6'd7  :iic_scl <= 1'b0;
                        6'd8  :iic_sda <= 1'b0;             //3
                        6'd9  :iic_scl <= 1'b1;
                        6'd11 :iic_scl <= 1'b0;
                        6'd12 :iic_sda <= 1'b0;             //4
                        6'd13 :iic_scl <= 1'b1;
                        6'd15 :iic_scl <= 1'b0;
                        6'd16 :iic_sda <= 1'b0;             //5
                        6'd17 :iic_scl <= 1'b1;
                        6'd19 :iic_scl <= 1'b0;
                        6'd20 :iic_sda <= 1'b0;             //6
                        6'd21 :iic_scl <= 1'b1;
                        6'd23 :iic_scl <= 1'b0;
                        6'd24 :iic_sda <= 1'b0;             //7
                        6'd25 :iic_scl <= 1'b1;
                        6'd27 :iic_scl <= 1'b0;
                        6'd28 :iic_sda <= 1'b0;             //8     
                        6'd29 :iic_scl <= 1'b1;
                        6'd31 :iic_scl <= 1'b0;
                        6'd33 :iic_scl <= 1'b1;             //ack
                        6'd34 :iic_st_done <= 1'b1;
                        6'd35 :begin
                                iic_scl <= 1'b0;
                                process_cnt <= 6'd0;
                        end
                        default:;
                    endcase
                end
                //write 0x40 -> write data
                iic_st_w_data    :begin
                    case(process_cnt)
                        6'd0  :iic_sda <= 1'b0;             //1
                        6'd1  :iic_scl <= 1'b1;
                        6'd3  :iic_scl <= 1'b0;
                        6'd4  :iic_sda <= 1'b1;             //2
                        6'd5  :iic_scl <= 1'b1;
                        6'd7  :iic_scl <= 1'b0;
                        6'd8  :iic_sda <= 1'b0;             //3
                        6'd9  :iic_scl <= 1'b1;
                        6'd11 :iic_scl <= 1'b0;
                        6'd12 :iic_sda <= 1'b0;             //4
                        6'd13 :iic_scl <= 1'b1;
                        6'd15 :iic_scl <= 1'b0;
                        6'd16 :iic_sda <= 1'b0;             //5
                        6'd17 :iic_scl <= 1'b1;
                        6'd19 :iic_scl <= 1'b0;
                        6'd20 :iic_sda <= 1'b0;             //6
                        6'd21 :iic_scl <= 1'b1;
                        6'd23 :iic_scl <= 1'b0;
                        6'd24 :iic_sda <= 1'b0;             //7
                        6'd25 :iic_scl <= 1'b1;
                        6'd27 :iic_scl <= 1'b0;
                        6'd28 :iic_sda <= 1'b0;             //8     
                        6'd29 :iic_scl <= 1'b1;
                        6'd31 :iic_scl <= 1'b0;
                        6'd33 :iic_scl <= 1'b1;             //ack
                        6'd34 :iic_st_done <= 1'b1;
                        6'd35 :begin
                                iic_scl <= 1'b0;
                                process_cnt <= 6'd0;
                        end
                        default:;
                    endcase
                end
                //write command or data
                iic_st_w_data_in :begin
                    case(process_cnt)
                        6'd0  :iic_sda <= iic_temp_w_data[7];             //1
                        6'd1  :iic_scl <= 1'b1;
                        6'd3  :iic_scl <= 1'b0;
                        6'd4  :iic_sda <= iic_temp_w_data[6];             //2
                        6'd5  :iic_scl <= 1'b1;
                        6'd7  :iic_scl <= 1'b0;
                        6'd8  :iic_sda <= iic_temp_w_data[5];             //3
                        6'd9  :iic_scl <= 1'b1;
                        6'd11 :iic_scl <= 1'b0;
                        6'd12 :iic_sda <= iic_temp_w_data[4];             //4
                        6'd13 :iic_scl <= 1'b1;
                        6'd15 :iic_scl <= 1'b0;
                        6'd16 :iic_sda <= iic_temp_w_data[3];             //5
                        6'd17 :iic_scl <= 1'b1;                    
                        6'd19 :iic_scl <= 1'b0;
                        6'd20 :iic_sda <= iic_temp_w_data[2];             //6
                        6'd21 :iic_scl <= 1'b1;                    
                        6'd23 :iic_scl <= 1'b0;
                        6'd24 :iic_sda <= iic_temp_w_data[1];             //7
                        6'd25 :iic_scl <= 1'b1;           
                        6'd27 :iic_scl <= 1'b0;
                        6'd28 :iic_sda <= iic_temp_w_data[0];             //8     
                        6'd29 :iic_scl <= 1'b1;                   
                        6'd31 :iic_scl <= 1'b0;
                        6'd33 :iic_scl <= 1'b1;             //ack
                        6'd34 :iic_st_done <= 1'b1;
                        6'd35 :begin
                                iic_scl <= 1'b0;
                                process_cnt <= 6'd0;
                        end
                        default:;
                    endcase
                end
                //set scl 1 sda 1
                iic_st_stop      :begin
                    case(process_cnt)
                        6'd0  : iic_sda <= 1'b0;
                        6'd1  : iic_scl <= 1'b1;
                        6'd3  : iic_sda <= 1'b1;    
                        6'd5 : iic_st_done <= 1'b1;
                        6'd6 : begin
                            process_cnt <= 6'd0;
                            iic_done <= 1'b1; 
                            end
                        default:;
                    endcase
                end
            endcase
        end
end
/************************************************************************************************************/

endmodule