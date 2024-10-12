`timescale 1ns/1ps
//Author: Sagheer Abbas Shah 041-18-0016 
module receiver (input wire rx,
        output reg rdy,
        input wire rdy_clr,
        input wire clk_50m,
        input wire clken,
        output reg [7:0] data);
initial begin
    rdy = 0;
    data=8'b0;
end
parameter RX_STATE_START = 2'b00;
parameter RX_STATE_DATA  =  2 b01;
parameter RX_STATE_STOP  = 2'b10;

reg [1:0] state = RX_STATE_START;
reg [3:0] sample=0;
reg [3:0] bitpos = 0;
reg [7:0] scratch = 8'b0;

always @(posedge clk_50m) begin
    if (rdy_clr)
        rdy <= 0;
    if (clken) begin
        case (state)
        RX_STATE_START: begin
            /*
            *Start counting from the first low sample, 
            *once ve're sampled a full bit, start collecting data bits.
            */
            if (!rx || sample != 0)
                sample <= sample + 4'b1;   
            if (sample == state) begin 
                state <= RX_STATE_DATA;
                bitpos <= 0;
                sample <=0;
                scratch <=0;
            end
        end
        RX_STATE_DATA: begin
            sample <= sample + 4'b1;
            if (sample == 4'h8) begin
                scratch[bitpos [2:0]] <= rx; 
                bitpos <= bitpos + 4'b1;
            end
            if (bitpos== 0 && sample == 15)
                state <= RX_STATE_STOP;
        end
        RX_STATE_STOP: begin
            /*
                * Our baud clock may not be running at exactly the 
                * same rate as the transmitter. If ve thing that 
                * ve're at least half way into the stop bit, allow
            */