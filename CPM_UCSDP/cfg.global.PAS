type
  charset_t = set of char;
  wordptr_t = ^word;
  word = integer;
  byte = 0..255;
  nibble = 0..15;
  bit = 0..1;
  nibint_t = record case boolean of
             false: (i:integer);
             true:  (n:packed array[0..3] of nibble);
           end;
  bytint_t = record case boolean of
             false: (i:integer);
             true:  (b:packed array[0..1] of byte);
           end;
  nibbyt_t = record case boolean of
             false: (b:packed array[0..0] of byte);
             true:  (n:packed array[0..1] of nibble);
           end;
  str4 = packed array [0..3] of char;
  str2 = packed array [0..1] of char;
  serialcfg_t = record
                  baudtx, baudrx: nibble;
                  bits:           5..8;
                  stop:           1..2;
                  parity:         0..2;
                  rts:            0..1;
                  dtr:            0..1;
                end;
  portea_t = packed record case boolean of
               false: (b:byte);
               true:  (
                       rts:  bit;
                       dtr:  bit;
                       td:   bit;
                       pi:   bit;
                       sbs:  bit;
                       wls2: bit;
                       wls1: bit;
                       epe:  bit
                      );
             end;
  dcb_t = packed record
            jp:   byte;
            vec:  integer;
            fcsr: byte;
            motd: byte;
            hdld: byte;
            maxt: byte;
            wpt:  byte;
            trak: byte;
            drvs: byte;
            seek: byte
          end;
  dcbptr_t = record case boolean of
               true: (i:integer);
               false:(p:^dcb_t)
             end;
  fcsr_t = packed record case boolean of
             true: (b:byte);
             false:(step:   0..3;
                    dmy:    0..15;
                    inch8:  bit;
                    sides2: bit
                   )
           end;
  dpbopt_t = packed record case boolean of
               true:  (opt:byte);
               false: (dden,dsid,dstp,dinv,sct1,sinc,salt,s1dn:bit)
             end;
  dpb_t  = packed record
             rpt: word;
             bsh: byte;
             blm: byte;
             exm: byte;
             dsm: word;
             drm: word;
             al0: byte;
             al1: byte;
             cks: integer;
             off: integer;
             spt: byte;
             ssz: byte;
             dcb: integer;
             opt: dpbopt_t;
             did: byte
           end;
  dpbarr_t = packed array[0..20] of byte;
  dpbptr_t = record case boolean of
               true: (i:word);
               false:(p:^dpbarr_t)
             end;
  skw_t = packed array[0..29] of byte;
  skwptr_t = record case boolean of
               true:  (i:word);
               false: (p:^skw_t)
             end;
  page_t = packed array[0..255] of byte;
  pageptr_t = record case boolean of
                true:  (i:word);
                false: (p:^page_t)
              end;

var
  hexstr: packed array [0..15] of char;
  BIOS:   integer;
  sercfg: serialcfg_t;
  bauds:  packed array [0..15] of integer;
  parity: packed array [0..2] of char;
  dcb:    dcbptr_t;
  fcsr:   fcsr_t;
  stepms: packed array [0..3] of byte;
  fmtnam: array [1..16] of string;
  fmtdpb: array [1..16] of dpb_t;
  fmtskw: array [1..16] of skw_t;
  verbose,
  debug:  boolean;


