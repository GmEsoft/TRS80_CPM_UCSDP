procedure loadSerial;
var addr: integer;
    hex:  str4;
    b:    byte;
    nb:   nibbyt_t;
    ea:   portea_t;
begin
  addr := deek( BIOS + 73 ); {SPDCB}
  b := peek( addr + 4 );
  nb.b[0] := b;
  sercfg.baudtx := nb.n[0];
  sercfg.baudrx := nb.n[1];
  b := peek( addr + 5 );
  hexword( b, hex );
  if debug then
    write( 'FLAGS=', hex );
    {7:EPE,6:WLS1,5:WLS2,4:SBS,3:PI}
  ea.b := b;
  sercfg.bits := 5 + ea.wls1 + 2 * ea.wls2;
  sercfg.stop := 1 + ea.sbs;
  sercfg.parity := ( 1 - ea.pi ) * ( 1 + ea.epe );
  sercfg.dtr := 1 - ea.dtr;
  sercfg.rts := 1 - ea.rts;
end;

procedure saveSerial;
var addr: integer;
    nb:   nibbyt_t;
    ea:   portea_t;
begin
  addr := deek( BIOS + 73 ); {SBDCB}
  nb.n[0] := sercfg.baudtx;
  nb.n[1] := sercfg.baudrx;
  poke( addr + 4, nb.b[0] );
  ea.b := 0;
  ea.td := 1;
  ea.wls1 := ( sercfg.bits - 5 ) MOD 2;
  ea.wls2 := ( sercfg.bits - 5 ) DIV 2;
  ea.sbs := sercfg.stop - 1;
  if sercfg.parity = 0 then begin
    ea.pi := 1; ea.epe := 0
  end else begin
    ea.pi := 0; ea.epe := sercfg.parity - 1
  end;
  poke( addr + 5, ea.b );
  writeln( 'Serial configuration updated' );
end;

procedure showSerial;
begin
  writeln;
  writeln( 'Baud Rate - TX: ', bauds[sercfg.baudtx] );
  writeln( '            RX: ', bauds[sercfg.baudrx] );
  writeln;
  writeln( 'Data Bits     : ', sercfg.bits );
  writeln( 'Parity        : ', parity[sercfg.parity] );
  writeln( 'Stop Bits     : ', sercfg.stop );
  writeln( 'DTR line      : ', sercfg.dtr );
  writeln( 'RTS line      : ', sercfg.rts );
end;

procedure serialMenu;
var loop: boolean;
begin
  loadSerial;
  loop := true;
  while loop do begin
    showSerial;
    case getCommand( 
         'Config Serial: T(xBaud, R(xBaud, D(ataBits, P(arity, S(top, Q(uit? ',
         ['T','R','D','P','S','Q'] ) of
      'T': sercfg.baudtx := ( sercfg.baudtx + 1 ) MOD 16;
      'R': sercfg.baudrx := ( sercfg.baudrx + 1 ) MOD 16;
      'D': sercfg.bits   := 5 + ( sercfg.bits - 4 ) MOD 4;
      'P': sercfg.parity := ( sercfg.parity + 1 ) MOD 3;
      'S': sercfg.stop   := 3 - sercfg.stop;
      'Q': loop := false;
    end;
  end;
  showSerial;
  case getCommand( 'Config Serial: E(xit without update, U(pdate and leave ?',
       ['E','U'] ) of
    'U': saveSerial;
  end;
end;

