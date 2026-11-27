module booth32_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [31:0] multiplicand,
    input  logic [31:0] multiplier,
    output logic [63:0] product,
    output logic        done
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        INIT = 2'b01,
        CALC = 2'b10,
        DONE = 2'b11
    } state_t;

    state_t state, next_state;

    // Datapath registers (A diperlebar 33-bit untuk mencegah overflow pada -2^31)
    logic signed [32:0] reg_a, next_a;
    logic        [31:0] reg_q, next_q;
    logic               reg_qm1, next_qm1;
    logic signed [32:0] reg_m, next_m;
    logic        [4:0]  count, next_count;
    logic        [63:0] reg_prod, next_prod;

    // Sinyal bantu kombinasional untuk operasi Booth & Arithmetic Right Shift
    logic signed [32:0] a_temp;
    logic signed [65:0] shifted;

    // Register sekuensial dengan synchronous active-low reset
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state    <= IDLE;
            reg_a    <= 33'sd0;
            reg_q    <= 32'd0;
            reg_qm1  <= 1'b0;
            reg_m    <= 33'sd0;
            count    <= 5'd0;
            reg_prod <= 64'd0;
        end else begin
            state    <= next_state;
            reg_a    <= next_a;
            reg_q    <= next_q;
            reg_qm1  <= next_qm1;
            reg_m    <= next_m;
            count    <= next_count;
            reg_prod <= next_prod;
        end
    end

    // Logika kontrol FSM & datapath kombinasional (bebas latch)
    always_comb begin
        // Default assignment agar tidak terbentuk latch
        next_state = state;
        next_a     = reg_a;
        next_q     = reg_q;
        next_qm1   = reg_qm1;
        next_m     = reg_m;
        next_count = count;
        next_prod  = reg_prod;
        a_temp     = reg_a;
        shifted    = {reg_a, reg_q, reg_qm1};

        case (state)
            IDLE: begin
                if (start) begin
                    next_state = INIT;
                end
            end

            INIT: begin
                next_a     = 33'sd0;
                next_q     = multiplier;
                next_qm1   = 1'b0;
                next_m     = $signed({multiplicand[31], multiplicand});
                next_count = 5'd0;
                next_state = CALC;
            end

            CALC: begin
                // Evaluasi pasangan bit (Q[0], Q[-1])
                case ({reg_q[0], reg_qm1})
                    2'b01:   a_temp = reg_a + reg_m;
                    2'b10:   a_temp = reg_a - reg_m;
                    default: a_temp = reg_a;
                endcase

                // Arithmetic Right Shift 1-bit pada {A, Q, Q[-1]}
                shifted  = $signed({a_temp, reg_q, reg_qm1}) >>> 1;
                next_a   = shifted[65:33];
                next_q   = shifted[32:1];
                next_qm1 = shifted[0];

                if (count == 5'd31) begin
                    next_prod  = {shifted[64:32], shifted[31:1]};
                    next_state = DONE;
                end else begin
                    next_count = count + 5'd1;
                end
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    assign product = reg_prod;
    assign done    = (state == DONE);

endmodule
