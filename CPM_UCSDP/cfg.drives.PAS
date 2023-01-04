procedure drivesMenu;
var loop:  boolean;
    n:     integer;
    addr:  integer;
begin
  loop := true;
  while loop do begin
    writeln;
    writeln( 'Drive Type Tracks Sides Step' );
    for n := 0 to 3 do begin
      addr := deek( BIOS + 57 + n + n );
      dcb.i := addr;
      fcsr.b := dcb.p^.fcsr;
      with fcsr do 
        writeln( '[ ',n, ' ]   ',5+3*inch8,'"     ',dcb.p^.maxt,'     ',
          sides2+1,'   ',((2-inch8)*stepms[step]):2 );
    end;
        
    case getCommand(
         'Config Drives: 0..3, Q(uit? ',
         ['0','1','2','3','Q'] ) of
      '0': n := 0;
      '1': n := 1;
      '2': n := 2;
      '3': n := 3;
      'Q': loop := false;
    end;
    if loop then begin
      addr := deek( BIOS + 57 + n + n );
      if debug then begin
        write( 'DCB', n,'=' );writehex( addr );writeln;
      end;
      dcb.i := addr;
      fcsr.b := dcb.p^.fcsr;
      with fcsr,dcb.p^ do 
      while loop do begin
        writeln;
        writeln( 'Current settings - Drive ', n, ':' );
        writeln;
        writeln( '[ A ]  Type of drive:     ', 5+3*inch8, ' inch' );
        writeln( '[ B ]  Number of tracks:  ', maxt );
        writeln( '[ C ]  Number of sides:   ', sides2 + 1 );
        writeln( '[ D ]  Step rate (ms):    ',
                                       ( 2 - inch8 ) * stepms[step] );
        case getCommand( 'Config Drive: A..D, Q(uit? ',
             ['A','B','C','D','Q'] ) of
          'A': begin
                 inch8 := 1 - inch8;
                 if inch8 > 0 then
                   maxt := 77
                 else
                   maxt := 40
               end;
          'B': if inch8 = 0 then
                 case maxt of
                   35: maxt := 40;
                   40: maxt := 77;
                   77: maxt := 80;
                   80: maxt := 35;
                 end;
          'C': sides2 := 1 - sides2;
          'D': step := ( step + 1 ) MOD 4;
          'Q': loop := false;
        end;
      end;{while}
      dcb.p^.fcsr  := fcsr.b;
      loop := true;
    end;{if}
  end;{while}
end;{proc}

