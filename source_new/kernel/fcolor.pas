{
Projeto FolhaLivre - Folha de Pagamento Livre
Formul�rio para Pesquisa em um DataSet

Copyright (c) 2002-2005 Allan Lima

Este programa � um software de livre distribui��o, que pode ser copiado e
distribu�do sob os termos da Licen�a P�blica Geral GNU, conforme publicada
pela Free Software Foundation, vers�o 2 da licen�a ou qualquer vers�o posterior.

Este programa � distribu�do na expectativa de ser �til aos seus usu�rios,
por�m  N�O TEM NENHUMA GARANTIA, EXPL�CITAS OU IMPL�CITAS,
COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.

Consulte a Licen�a P�blica Geral GNU para maiores detalhes.

@project-name: FolhaLivre
@project-email: folha_livre@yahoo.com.br
@autor-name: Allan Lima
@autor-email: allan_kardek@yahoo.com.br

Hist�rico das modifica��es

* 19/11/2007 - Primeira vers�o

}

unit fcolor;

{$I flivre.inc}

interface

uses
  {$IFDEF VCL}Graphics{$ENDIF}
  {$IFDEF CLX}QGraphics{$ENDIF};

procedure kSetColor(Cor: TColor); overload;
procedure kSetColor(Cor: String); overload;
function  kGetColor:TColor;

procedure kSetColorProgram(Cor: TColor); overload;
procedure kSetColorProgram(Cor: String); overload;
function  kGetColorProgram:TColor;

procedure kSetColorTitle(Cor: TColor); overload;
procedure kSetColorTitle(Cor: String); overload;
function  kGetColorTitle: TColor;

implementation

var
  cMain: TColor;
  cProgram: TColor;
  cTitle: TColor;

procedure kSetColor(Cor: TColor);
begin
  cMain := Cor;
end;

procedure kSetColor(Cor: String);
begin
  cMain := StringToColor(Cor);
end;

function kGetColor: TColor;
begin
  Result := cMain;
end;

procedure kSetColorProgram(Cor: TColor);
begin
  cProgram := Cor;
end;

procedure kSetColorProgram(Cor: String);
begin
  cProgram := StringToColor(Cor);
end;

function kGetColorProgram: TColor;
begin
  Result := cProgram;
end;

procedure kSetColorTitle(Cor: TColor);
begin
  cTitle := Cor;
end;

procedure kSetColorTitle(Cor: String);
begin
  cTitle := StringToColor(Cor);
end;

function kGetColorTitle: TColor;
begin
  Result := cTitle;
end;

initialization
  cMain := $00E0E9EF;
  cProgram := clTeal;
  cTitle := clBlack;

end.
