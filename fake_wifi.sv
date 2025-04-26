pcileech_bar_impl_fake_wifi i_barX(
    .rst            ( rst                           ),
    .clk            ( clk                           ),
    .wr_addr        ( wr_addr                       ),
    .wr_be          ( wr_be                         ),
    .wr_data        ( wr_data                       ),
    .wr_valid       ( wr_valid && wr_bar[X]         ),
    .rd_req_ctx     ( rd_req_ctx                    ),
    .rd_req_addr    ( rd_req_addr                   ),
    .rd_req_valid   ( rd_req_valid && rd_req_bar[X] ),
    .rd_rsp_ctx     ( bar_rsp_ctx[X]                ),
    .rd_rsp_data    ( bar_rsp_data[X]               ),
    .rd_rsp_valid   ( bar_rsp_valid[X]              )
);

module pcileech_bar_impl_fake_wifi (
    input               rst,
    input               clk,
    input [31:0]        wr_addr,
    input [3:0]         wr_be,
    input [31:0]        wr_data,
    input               wr_valid,
    input [87:0]        rd_req_ctx,
    input [31:0]        rd_req_addr,
    input               rd_req_valid,
    output reg [87:0]   rd_rsp_ctx,
    output reg [31:0]   rd_rsp_data,
    output reg          rd_rsp_valid
);

    localparam REG_LINK_STATUS = 32'h0000; // Connection status
    localparam REG_SCAN_RESULT = 32'h0004; // Select Wi-Fi to connect
    localparam REG_SSID        = 32'h0008; // Current connected SSID
    localparam REG_RSSI        = 32'h000C; // Current signal strength (RSSI)
    localparam REG_SCAN_COUNT  = 32'h0010; // Number of available networks
    localparam REG_SCAN_ENTRY  = 32'h0014; // Get SSID based on index

    localparam STATE_IDLE           = 0;
    localparam STATE_SCANNING       = 1;
    localparam STATE_AUTHENTICATING = 2;
    localparam STATE_ASSOCIATING    = 3;
    localparam STATE_CONNECTED      = 4;

    reg [2:0] state;
    reg [31:0] counter;
    reg [7:0] connected_index;
    reg [7:0] rssi;
    reg [31:0] ssid;
    
    // Fake network entries (example SSID names)
    reg [31:0] ssid_table [0:3]; // 4 fake SSIDs
    reg [7:0] rssi_table [0:3];  // 4 corresponding RSSI values

    initial begin
        ssid_table[0] = 32'h486F6D65; // "Home"
        ssid_table[1] = 32'h43616665; // "Cafe"
        ssid_table[2] = 32'h426F7373; // "Boss"
        ssid_table[3] = 32'h46726565; // "Free"
        
        rssi_table[0] = 90; // "Home" Wi-Fi signal strength
        rssi_table[1] = 75; // "Cafe" Wi-Fi signal strength
        rssi_table[2] = 60; // "Boss" Wi-Fi signal strength
        rssi_table[3] = 50; // "Free" Wi-Fi signal strength
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= STATE_IDLE;
            counter         <= 0;
            connected_index <= 0;
            ssid            <= ssid_table[0];
            rssi            <= rssi_table[0];
        end else begin
            counter <= counter + 1;
            case (state)
                STATE_IDLE: begin
                    if (counter > 32'd1000) begin
                        state   <= STATE_SCANNING;
                        counter <= 0;
                    end
                end
                STATE_SCANNING: begin
                    if (counter > 32'd1000) begin
                        state   <= STATE_AUTHENTICATING;
                        counter <= 0;
                    end
                end
                STATE_AUTHENTICATING: begin
                    if (counter > 32'd500) begin
                        state   <= STATE_ASSOCIATING;
                        counter <= 0;
                    end
                end
                STATE_ASSOCIATING: begin
                    if (counter > 32'd500) begin
                        state   <= STATE_CONNECTED;
                        counter <= 0;
                    end
                end
                STATE_CONNECTED: begin
                    // Slowly vary RSSI to simulate natural fluctuation
                    if (counter[7:0] == 8'hFF) begin
                        if (rssi > 45)
                            rssi <= rssi - 1;
                        else
                            rssi <= rssi_table[connected_index];
                    end
                end
            endcase
        end
    end

    // Write operations: select which Wi-Fi to connect to
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            connected_index <= 0;
        end else if (wr_valid) begin
            if (wr_addr == REG_SCAN_RESULT) begin
                if (wr_data < 4) begin
                    connected_index <= wr_data[1:0];
                    ssid <= ssid_table[wr_data[1:0]];
                    rssi <= rssi_table[wr_data[1:0]];
                end
            end
        end
    end

    // Read operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_rsp_ctx   <= 0;
            rd_rsp_data  <= 0;
            rd_rsp_valid <= 0;
        end else if (rd_req_valid) begin
            rd_rsp_ctx   <= rd_req_ctx;
            rd_rsp_valid <= 1'b1;
            case (rd_req_addr)
                REG_LINK_STATUS: rd_rsp_data <= (state == STATE_CONNECTED) ? 32'h1 : 32'h0;
                REG_SCAN_COUNT:  rd_rsp_data <= 32'd4; // Always 4 fake networks available
                REG_SSID:        rd_rsp_data <= ssid;
                REG_RSSI:        rd_rsp_data <= {24'd0, rssi};
                REG_SCAN_ENTRY: begin
                    case (counter[3:2]) // Cycle through SSIDs
                        2'd0: rd_rsp_data <= ssid_table[0];
                        2'd1: rd_rsp_data <= ssid_table[1];
                        2'd2: rd_rsp_data <= ssid_table[2];
                        2'd3: rd_rsp_data <= ssid_table[3];
                        default: rd_rsp_data <= 32'hDEADBEEF;
                    endcase
                end
                default: rd_rsp_data <= 32'hDEADBEEF;
            endcase
        end else begin
            rd_rsp_valid <= 0;
        end
    end

endmodule
