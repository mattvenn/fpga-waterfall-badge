`default_nettype none
//----------------------------------------------------------------------------
//-- Ejemplo de uso del transmisor serie
//-- Envio de la cadena "Hola!..." de forma continuada cuando se activa la 
//-- señal de DTR
//----------------------------------------------------------------------------
//-- (C) BQ. September 2015. Written by Juan Gonzalez (Obijuan)
//-- GPL license
//----------------------------------------------------------------------------
//-- Comprobado su funcionamiento a todas las velocidades estandares:
//-- 300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200
//----------------------------------------------------------------------------
`include "baudgen.vh"

//-- Modulo para envio de una cadena por el puerto serie
module top (input wire clk,  //-- Reloj del sistema
                input wire RX,  //-- Señal de DTR
                output wire TX,   //-- Salida de datos serie
	output LEDR_N
               );

//-- Velocidad a la que hacer las pruebas
parameter BAUD = `B115200;
parameter DATA_W = 8; 
parameter FREQ_BINS = 320;
localparam BIN_ADDR_W = $clog2(FREQ_BINS);



//-- Reset
reg rstn = 0;
reg samp_en;

//-- Señal de listo del transmisor serie
wire ready;

//-- Dato a transmitir (normal y registrado)
reg [7:0] data;
reg [7:0] data_r;

//-- Señal para indicar al controlador el comienzo de la transmision
//-- de la cadena. Es la de DTR registrada
reg transmit;

//-- Microordenes
reg cena;      //-- Counter enable (cuando cena = 1)
reg start;  //-- Transmitir cadena (cuando transmit = 1)


//------------------------------------------------
//-- 	RUTA DE DATOS
//------------------------------------------------

//-- Inicializador
always @(posedge clk)
  rstn <= 1;

//-- Instanciar la Unidad de transmision
uart_tx #(.BAUD(BAUD))
  TX0 (
    .clk(clk),
    .rstn(rstn),
    .data(data_r),
    .start(start),
    .ready(ready),
    .tx(TX)
  );

//-- Multiplexor con los caracteres de la cadena a transmitir
//-- se seleccionan mediante la señal car_count

parameter DW = 16;  // data width
parameter AW = 12; // address width - 4096 samples
localparam NPOS = 2 ** AW;

reg [AW-1:0] samp_count;
reg signed [DW-1: 0] samples [0: NPOS-1];

localparam SAMPLE_W = 12;

//-- Registrar los datos de salida del multiplexor
always @(posedge clk) begin
  // even numbers
  if (~ car_count[0] ) begin
      data_r <= samples[car_count/2][15:8];
  end else begin
      data_r <= samples[car_count/2][7:0];
  end
end

//-- Contador de caracteres
//-- Cuando la microorden cena esta activada, se incrementa
reg [AW:0] car_count; // 1 bit more than AW
reg [BIN_ADDR_W-1:0] tw_addr = 0;

wire [31:0] mult_out;

dsp_mult_16 mult16 ( .clock(clk), .A(A), .B(B), .X(mult_out));
wire signed [7:0] realA, realB;
// sign extend
wire signed [15:0] A ; //= { {8{realA[7]}}, realA[7:0] };
wire signed [15:0] B ; //= { {8{realB[7]}}, realB[7:0] };
twiddle_rom #(.ADDR_W(BIN_ADDR_W), .DATA_W(8)) twiddle_rom_0(.clk(clk), .addr(tw_addr), .dout_real(A), .dout_imag(B));

always @(posedge clk) begin
    if(rstn == 0)
        samp_count <= 0;
    else if (samp_en) begin
        samp_count <= samp_count + 1;
        tw_addr <= tw_addr + 1;
        samples[samp_count] <= mult_out[15:0];
    end else begin
        samp_count <= 0;
    end
end

always @(posedge clk)
  if (rstn == 0)
    car_count = 0;
  else if (cena)
    car_count = car_count + 1;

//-- Registrar señal dtr para cumplir con normas diseño sincrono
always @(posedge clk)
  transmit <= ~RX;

assign LEDR_N = state;

//----------------------------------------------------
//-- CONTROLADOR
//----------------------------------------------------
localparam IDLE = 3'd0;   //-- Reposo
localparam TXCAR = 3'd1;  //-- Transmitiendo caracter
localparam NEXT = 3'd2;   //-- Preparar transmision del sig caracter
localparam END = 3'd3;    //-- Terminar
localparam SAMP = 3'd4;    //-- Sample

//-- Registro de estado del automata
reg [2:0] state;

//-- Gestionar el cambio de estado
always @(posedge clk)

  if (rstn == 0)
    //-- Ir al estado inicial
    state <= IDLE;

  else
    case (state)
      //-- Estado inicial. Se sale de este estado al recibirse la
      //-- señal de transmit, conectada al DTR
      IDLE: 
        if (transmit == 1) state <= SAMP;
        else state <= IDLE;

      SAMP:
        if (samp_count == NPOS - 1) state <= TXCAR;
        else state <= SAMP;

      //-- Estado de transmision de un caracter. Esperar a que el 
      //-- transmisor serie este disponible. Cuando lo esta se pasa al
      //-- siguiente estado
      TXCAR: 
        if (ready == 1) state <= NEXT;
        else state <= TXCAR;

      //-- Envio del siguiente caracter. Es un estado transitorio
      //-- Cuando se llega al ultimo caracter se pasa para finalizar
      //-- la transmision 
      NEXT:	
        if (car_count == 2 * NPOS - 1) state <= END;
        else state <= TXCAR;

      //-- Ultimo estado:finalizacion de la transmision. Se espera hasta
      //-- que se haya enviado el ultimo caracter. Cuando ocurre se vuelve
      //-- al estado de reposo inicial
      END: 
        //--Esperar a que se termine ultimo caracter
        if (ready == 1) state <= IDLE;
        else state <= END;

      //-- Necesario para evitar latches
      default:
         state <= IDLE;

    endcase

//-- Generacion de las microordenes
always @(posedge clk)
  case (state)
    IDLE: begin
      start <= 0;
      cena <= 0;
      samp_en <= 0;
    end

    SAMP: begin
      samp_en <= 1;
    end

    TXCAR: begin
      start <= 1;
      cena <= 0;
      samp_en <= 0;
    end

    NEXT: begin
      start <= 0;
      cena <= 1;
      samp_en <= 0;
    end

    END: begin
      start <= 0;
      cena <= 0;
      samp_en <= 0;
    end

    default: begin
      start <= 0;
      cena <= 0;
      samp_en <= 0;
    end
  endcase

endmodule




