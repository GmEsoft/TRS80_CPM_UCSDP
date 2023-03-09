function toupper( ch:char ):char;
begin
  if ch in ['a'..'z'] then
    toupper := chr( ord(ch)-32 )
  else
    toupper := ch;
end;

procedure hexword( word: integer; var str:str4 );
var ni: nibint_t;
    j:  integer;
begin
  ni.i := word;
  for j := 0 to 3 do
    str[j] := hexstr[ni.n[3-j]];
end;

procedure writehex( word: integer );
var str: str4;
begin
  hexword( word, str );
  write( str );
end;

procedure dump( addr: integer; data: page_t );
var i,j  : integer;
    bi   : bytint_t;
    b    : byte;
begin
  i := 0;
  while i < 256 do begin
    writehex( addr + i );
    write( '  ' );
    for j := 0 to 7 do begin
      bi.b[0] := data[i+j+j+1];
      bi.b[1] := data[i+j+j];
      writehex( bi.i );
      write( ' ' );
    end;
    write( ' ' );
    for j := 0 to 15 do begin
      b := data[i+j];
      if ( b<32 ) or ( b>127 ) then
        write( '.' )
      else
        write( chr(b) )
    end;
    writeln;
    i := i + 16;
  end
end;

procedure cls;
begin
  write( chr(14), chr( 26 ) );
end;

function getOption( menu: string; options: charset_t ): char;
var ch:char;
begin
  write( menu, chr( 21 ) );
  repeat
    read( keyboard, ch );
    ch := toupper( ch );
  until ( ch in options );
  writeln( ch, chr( 23 ) );
  getOption := ch;
end;

function getCommand( menu: string; options: charset_t ): char;
var ch:char;
begin
  gotoxy( 0, 0 );
  getCommand := getOption( menu, options );
end;

