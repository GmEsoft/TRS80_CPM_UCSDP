function getWordPtr( addr: integer ):wordptr_t;
var ptr: record case boolean of
           true:(i:integer);
           false:(p:wordptr_t);
         end;
begin
  ptr.i := addr;
  getWordPtr := ptr.p;
end;

function deek( addr: integer ):integer;
var ptr:wordptr_t;
begin
  ptr := getWordPtr( addr );
  deek := ptr^;
end;

procedure doke( addr, word: integer );
var ptr:wordptr_t;
begin
  ptr := getWordPtr( addr );
  ptr^ := word;
end;

function peek( addr: integer ):byte;
var bi:bytint_t;
begin
  bi.i := deek( addr );
  peek := bi.b[0];
end;

procedure poke( addr: integer; data: byte );
var bi:bytint_t;
begin
  bi.i := deek( addr );
  bi.b[0] := data;
  doke( addr, bi.i );
end;

function bytint( low, high: byte ):integer;
var bi:bytint_t;
begin
  bi.b[0] := low;
  bi.b[1] := high;
  bytint  := bi.i;
end;

function intbyt( i, n: integer ):byte;
var bi:bytint_t;
begin
  bi.i := i;
  intbyt := bi.b[n];
end;


