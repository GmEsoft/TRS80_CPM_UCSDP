procedure loadDpb( var dpb: dpb_t; var a: dpbarr_t );
begin
  with dpb do begin
    rpt := bytint( a[0], a[1] );
    bsh := a[2];
    blm := a[3];
    exm := a[4];
    dsm := bytint( a[5], a[6] );
    drm := bytint( a[7], a[8] );
    al0 := a[9];
    al1 := a[10];
    cks := bytint( a[11], a[12] );
    off := bytint( a[13], a[14] );
    spt := a[15];
    ssz := a[16];
    dcb := bytint( a[17], a[18] );
    opt.opt := a[19];
    did := a[20]
  end;
end;

procedure saveDpb( var dpb: dpb_t; var a: dpbarr_t );
begin
  with dpb do begin
    a[0] := intbyt( rpt, 0 ); a[1] := intbyt( rpt, 1 );
    a[2] := bsh;
    a[3] := blm;
    a[4] := exm;
    a[5] := intbyt( dsm, 0 ); a[6] := intbyt( dsm, 1 );
    a[7] := intbyt( drm, 0 ); a[8] := intbyt( drm, 1 );
    a[9] := al0;
    a[10] := al1;
    a[11] := intbyt( cks, 0 ); a[12] := intbyt( cks, 1 );
    a[13] := intbyt( off, 0 ); a[14] := intbyt( off, 1 );
    a[15] := spt;
    a[16] := ssz;
    a[17] := intbyt( dcb, 0 ); a[18] := intbyt( dcb, 1 );
    a[19] := opt.opt;
    a[20] := did
  end;
end;

procedure formatMenu;
var ok,
    loop:  boolean;
    n,i:   integer;
    addr,
    dph,
    dpb,
    dcb:   integer;
    pdpb:  dpbptr_t;
    pdcb:  dcbptr_t;
    pskw:  skwptr_t;
    ldpb:  dpb_t;
    lfcsr: fcsr_t;
    did,
    dsel:  byte;
    ch,d:  char;
begin
  loop := true;
  while loop do begin
    cls;
    writeln;
    writeln;
    writeln( 'Drive   Physical drive & current format' );
    for n := 0 to 15 do begin
      ch := chr( ord( 'A' ) + n );
      write( '[ ',ch,' ]   ' );
      addr := deek( BIOS + 55 );
      dph  := deek( addr + n + n );
      if dph = 0 then begin
        writeln( '    Undefined disk drive' );
      end else begin
        dpb := deek( dph + 10 );
        dcb := deek( dpb + 17 );
        did := peek( dpb + 20 );
        if did > 0 then begin
          dsel := peek( dcb + 3 );
          i := 0;
          while dsel > 1 do begin
            i := i + 1;
            dsel := dsel DIV 2;
          end;
          writeln( i,':  ',fmtnam[did] );
        end else if deek( dph ) <> 0 then begin
          writeln( '    Hard Disk drive' );
        end else begin
          writeln( '    Fixed storage device' );
        end;
      end;
    end;
    d := getCommand(
         'Config Drives: A..P, Q(uit? ',
         ['A'..'P','Q'] );
    case d of
      'Q': loop := false;
    end;
    ok := loop;
    if ok then begin
      n := ord( d ) - ord( 'A' );
      addr := deek( BIOS + 55 );
      dph  := deek( addr + n + n );
      dpb  := deek( dph + 10 );
      dcb  := deek( dpb + 17 );
      if ( dph = 0 ) or ( deek(dph) = 0 ) or ( peek( dpb + 20 ) = 0 ) then
        ok := false;
    end;
    if ok then begin
      pdpb.i := deek( dph + 10 );
      if debug then begin
        write( 'DPHTBL=' );writehex( addr );
        write( ' DPH',d,'=' );writehex( dph );
        write( ' DPB',d,'=' );writehex( dpb );
        write( ' DCB',d,'=' );writehex( dcb );writeln;
        writehex( pdpb.i );
        write( ':' );
      end;
      loadDpb( ldpb, pdpb.p^ );
      if verbose then with ldpb do begin
        write( rpt,',',bsh,',',blm,',',exm,',',dsm,',',drm,',',
               al0,',',al1,',',cks,',',off,',',spt,',',ssz,',' );
        writehex( dcb );
        writeln( ',',opt.opt,',',did );
      end;
      loop := true;
      writeln;
      writeln( 'Choose the format to be used for drive ',d,':' );
      writeln;
      for i := 1 to 16 do begin
        writeln( '[ ',chr(ord('A')+i-1),' ]  ',fmtnam[i] );
      end;
      ch := getCommand( 'Config Drive Format: A..P, Q(uit? ',
                        ['A'..'P','Q'] );
      if ch <> 'Q' then begin
        i := ( ord(ch) - ord('A') ) + 1;
        writeln;
        writeln( 'Format selected for drive ', d, ':' );
        writeln( '>>--> ', fmtnam[i] );
        writeln;
        ch := getOption(
              'Which physical disk drive is to be used: 0..3, Q(uit? ',
                          ['0'..'3','Q'] );
        if ch <> 'Q' then begin
          pdcb.i := deek( BIOS + 57 + 2 * ( ord(ch) - ord('0') ) );
          if debug then begin
            write( 'DCB',ch,'=' );writehex( pdcb.i );writeln;
          end;
          with pdcb.p^, fmtdpb[i] do begin
            lfcsr.b := fcsr;
            if debug then begin
              writeln( 'trks=',dcb,' maxt=',maxt,' fcsr=',lfcsr.b,
                ' opt=',opt.opt,' dsid=',opt.dsid,' sides2=',lfcsr.sides2 );
              with opt do
                writeln (dden,dsid,dstp,dinv,sct1,sinc,salt,s1dn);
            end;
            ok := false;
            if dcb > maxt then
              writeln( 'Exceeding max tracks number' )
            else if opt.dsid > lfcsr.sides2 then
              writeln( 'Exceeding max sides number' )
            else begin
              ok := true;
              ldpb := fmtdpb[i];
              ldpb.dcb := pdcb.i;
              if dcb + dcb <= maxt then
                if getOption( 'Double step [Y/N] ? ', ['Y','N'] ) = 'Y' then
                  ldpb.opt.dstp := 1;
              saveDpb( ldpb, pdpb.p^ );
              pskw.i := deek( dph );
              pskw.p^ := fmtskw[i];
            end;{if}
            if not ok then
              ch := getOption(
                'Disk format incompatible with this drive! Press <spacebar>',
                [' '] );
          end;{with}
        end;{if}
      end;{if}
    end;{if}
  end;{while}
end;{proc}

