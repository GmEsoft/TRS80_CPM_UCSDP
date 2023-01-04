procedure setMenu;
var loop:boolean;
begin
  loop := true;
  while loop do begin
    writeln( 'D(ebug:   ', -ord(debug) );
    writeln( 'V(erbose: ', -ord(verbose) );
    case getCommand( 'Config settings: {options} <spacebar> to leave',
                   ['D','V',' ']  ) of
      'D': begin debug := not debug; verbose := verbose or debug end;
      'V': begin verbose := not verbose; debug := debug and verbose end;
      ' ': loop := false;
    end;
  end;
end;

procedure defFmt(
  n: integer;
  prpt: word;
  pbsh, pblm, pexm: byte;
  pdsm, pdrm: word;
  pal0, pal1: byte;
  pcks, poff: word;
  pspt, pssz: byte;
  pdcb: word;
  popt: byte
);
const skew = 2;
var p,i,j:integer;
begin
  with fmtdpb[n] do begin
    rpt := prpt; bsh := pbsh; blm := pblm; exm := pexm;
    dsm := pdsm; drm := pdrm; al0 := pal0; al1 := pal1;
    cks := pcks; off := poff; spt := pspt; ssz := pssz;
    dcb := pdcb; opt.opt := popt; did := n
  end;
  p := 0;
  for i := 0 to skew - 1 do begin
    j := i;
    while j < pspt do begin
      fmtskw[n][p] := j + 1;
      p := p + 1;
      j := j + skew
    end
  end;
  while p < 30 do begin
    fmtskw[n][p] := 0;
    p := p + 1
  end;
  if debug then begin
    write( n, ': ' );
    for p := 0 to 29 do
      write( fmtskw[n][p], ' ' );
    writeln;
  end
end;

procedure init;
begin
  debug := false;
  verbose := false;
  hexstr := '0123456789ABCDEF';
  parity := 'NOE';
  bauds[0] := 50;
  bauds[1] := 75;
  bauds[2] := 110;
  bauds[3] := 134;
  bauds[4] := 150;
  bauds[5] := 300;
  bauds[6] := 600;
  bauds[7] := 1200;
  bauds[8] := 1800;
  bauds[9] := 2000;
  bauds[10] := 2400;
  bauds[11] := 3600;
  bauds[12] := 4800;
  bauds[13] := 7200;
  bauds[14] := 9600;
  bauds[15] := 19200;
  stepms[0] := 3;
  stepms[1] := 6;
  stepms[2] := 10;
  stepms[3] := 15;
  fmtnam[1] := 'MM Std SYSTEM (40T SS DD 170K)';
  fmtnam[2] := 'MM Std DATA (40T SS DD 200K)';
  fmtnam[3] := 'MM Std DS SYSTEM (40T DS DD 350K)';
  fmtnam[4] := 'MM Std DS DATA (40T DS DD 400K)';
  fmtnam[5] := 'MM 80T SYSTEM (80T SS DD 350K)';
  fmtnam[6] := 'MM 80T DATA (80T SS DD 400K)';
  fmtnam[7] := 'MM 80T DS SYSTEM (80T DS DD 710K)';
  fmtnam[8] := 'MM 80T DS DATA (80T DS DD 800K)';
  fmtnam[9] := '09';
  fmtnam[10] := '10';
  fmtnam[11] := '11';
  fmtnam[12] := '12';
  fmtnam[13] := '13';
  fmtnam[14] := '14';
  fmtnam[15] := '15';
  fmtnam[16] := '16';
  defFmt( 1, 36, 4, 15, 1,  84, 127, 192, 0, 32, 2, 18, 1, 40, 128 );
  defFmt( 2, 40, 4, 15, 1,  99, 127, 192, 0, 32, 0, 10, 2, 40, 128 );
  defFmt( 3, 36, 4, 15, 1, 174, 127, 192, 0, 32, 2, 18, 1, 40, 192 );
  defFmt( 4, 40, 4, 15, 1, 199, 127, 192, 0, 32, 0, 10, 2, 40, 192 );
  defFmt( 5, 36, 4, 15, 1, 174, 127, 192, 0, 32, 2, 18, 1, 80, 128 );
  defFmt( 6, 40, 4, 15, 1, 199, 127, 192, 0, 32, 0, 10, 2, 80, 128 );
  defFmt( 7, 36, 4, 15, 1, 354, 127, 192, 0, 32, 2, 18, 1, 80, 192 );
  defFmt( 8, 40, 4, 15, 1, 399, 127, 192, 0, 32, 0, 10, 2, 80, 192 );
end;

