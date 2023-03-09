(*$S+*)
program config;

(*$I CFG.GLOBAL *)

(*$I CFG.MEMORY *)
(*$I CFG.DIALOG *)

(*$I CFG.SERIAL *)
(*$I CFG.DRIVES *)
(*$I CFG.FORMAT *)
(*$I CFG.INIT *)

procedure keyDef;
var addr:  integer;
begin
  if getCommand( 'keyDef: reconfigure keys [Y/N] ?', ['Y','N'] ) = 'Y' then
  begin
    addr := deek( BIOS + 67 ); {Kbd DCB}
    poke( addr + 18,  0 ); {Caps Lock OFF}
    poke( addr + 36, 27 ); {Clear -> ESC}
    poke( addr + 37, 27 ); {Break -> ESC}
    poke( addr + 60, 24 ); {Sh-Clear -> Clear}
    poke( addr + 61, 27 ); {Sh-Break -> ESC}
    writeln( '<BREAK> and <CLEAR> reconfigured; <CAPS> reset' );
  end
end;

procedure printMenu;
var addr:  integer;
    ch:    char;
    lines: integer;
    loop:  boolean;
    bits:  byte;
    noLF,
    softFF:boolean;
begin
  loop := true;
  addr := deek( BIOS + 71 ); {Printer DCB}
  bits := peek( addr + 1 );
  noLF := ( odd( bits ) and odd( 1 ) ) <> false;
  softFF := ( odd( bits ) and odd( 2 ) ) <> false;
  lines := peek( addr + 3 );
  while loop do begin
    cls;
    writeln;
    writeln;
    writeln( '[ A ]  Suppress linefeed after carriage return: ',
      ord( noLF ) );
    writeln( '[ B ]  Simulate formfeed (top-of-form code):    ',
      ord( softFF ) );
    writeln( '[ C ]  Page length in lines: ', lines );
    ch := getCommand( 'Config Printer: {options}, Q(uit? ',
        ['A'..'C','Q'] );
    if ch = 'A' then begin
      noLF := noLF = false
    end else if ch = 'B' then begin
      softFF := softFF = false
    end else if ch = 'C' then begin
      write( 'Enter new page length: ' );
      readln( lines )
    end else if ch = 'Q' then begin
      loop := false
    end
  end;
  bits := ord( ( odd(bits) and not odd(3) ) or noLF or odd( 2*ord(softFF) ) );
  poke( addr + 1, bits );
  poke( addr + 3, lines );
end;

procedure memory;
var addr: integer;
    ch:   char;
    loop: boolean;
    ppage:pageptr_t;
begin
  addr := 0;
  loop := true;
  while loop do begin
    ppage.i := addr;
    dump( addr, ppage.p^ );
    ch := getCommand( 'Memory: N(ext, P(rev, >, <, Q(uit ?',
      ['N','P',';','-','>','<','Q'] );
    if ch = 'Q' then
      loop := false
    else if ( ch=';' ) or ( ch='N' ) then
      addr := addr + 256
    else if ( ch='-' ) or ( ch='P' ) then
      addr := addr - 256
    else if ch='>' then
      addr := addr + 4096
    else if ch='<' then
      addr := addr - 4096
  end
end;
  

procedure blocks;
var sect: integer;
    ch:   char;
    loop: boolean;
    page: page_t;
    dev:  integer;
begin
  dev := 4;
  sect := 0;
  loop := true;
  unitclear( dev );
  while loop do begin
    unitread( dev, page[0], 128, sect, 2 );
    unitread( dev, page[128], 128, sect+1, 2 );
    dump( sect*128, page );
    ch := getCommand( 'Disk: N(ext, P(rev, >, <, Q(uit ?',
      ['N','P',';','-','>','<','Q'] );
    if ch = 'Q' then
      loop := false
    else if ( ch=';' ) or ( ch='N' ) then
      sect := sect + 2
    else if ( ch='-' ) or ( ch='P' ) then
      sect := sect - 2
    else if ch='>' then
      sect := sect + 32
    else if ch='<' then
      sect := sect - 32
  end
end;

procedure writeConfig;
type sec_t = packed array[0..127] of byte;
     secptr_t = record case boolean of
                  true:  (i:integer);
                  false: (p:^sec_t)
                end;
var nsecs,
    sec,
    i,
    dph,
    dpb   : integer;
    psec  : secptr_t;
    page  : page_t;
begin
  dph := deek( deek( BIOS + 55 ) );
  dpb := deek( dph + 10 );
  if peek( dpb + 20 ) > 0 then
    nsecs := 26
  else
    nsecs := 52;
  psec.i := deek( 1 ) - 3;
  writehex( psec.i );
  write( ',', nsecs, ' sectors: ' );
  sec := 46;
  for i := 1 to nsecs do begin
    if debug then begin
      write( sec, ':' );
      writehex( psec.i )
    end;
    unitwrite( 4, psec.p^, 128, sec, 2 );
    if ioresult <> 0 then
      write( '<', ioresult, '>' );
    psec.i := psec.i + 128;
    sec := sec + 1;
    write( '.' )
  end;
  unitread( 4, page, 128, 0, 2 );
  writeln;
  writeln( 'Configuration saved' );
end;

procedure mainMenu;
var loop: boolean;
    wptr: wordptr_t;
    hex:  str4;
    ver:  byte;
begin
  loop := true;
  bios := deek( 1 ) - 3;
  ver  := peek( BIOS + 54 );
  gotoxy( 0, 8 );
  writeln( 'Welcome to:' );
  writeln;
  writeln( 'TRS-80 Model 4 ',intbyt(BIOS,1)DIV 4+6,'k CP/M v2.22 -',
    ' Montezuma Micro BIOS r', ver DIV 16, '.', ver MOD 16, 'x',
    ' CONFIG version 0.94' );
  writeln;
  hexword( bios, hex );
  write( 'BIOS base: ', hex );
  while loop do begin
    case getCommand( 
      'Config: S(erial, K(eys, P(rntr, D(rvs, F(rmts, M(emory, B(lks, W(rite, Q(uit? ',
                   ['S','K','P','D','F','M','B','Z','W','Q']  ) of
      'S': serialMenu;
      'K': keyDef;
      'P': printMenu;
      'D': drivesMenu;
      'F': formatMenu;
      'M': memory;
      'B': blocks;
      'W': writeConfig;
      'Z': setMenu;
      'Q': loop := false;
    end;
  end;
end;

begin
  cls;
  writeln;
  init;
  mainMenu;
end.

