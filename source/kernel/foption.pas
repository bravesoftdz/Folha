{
Projeto FolhaLivre - Folha de Pagamento Livre

Copyright (C) 2007 Allan Lima

Este programa � um software de livre distribui��o, que pode ser copiado e
distribu�do sob os termos da Licen�a P�blica Geral GNU, conforme publicada
pela Free Software Foundation, vers�o 2 da licen�a ou qualquer vers�o posterior.

Este programa � distribu�do na expectativa de ser �til aos seus usu�rios,
por�m  N�O TEM NENHUMA GARANTIA, EXPL�CITAS OU IMPL�CITAS,
COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.

Consulte a Licen�a P�blica Geral GNU para maiores detalhes.
}

unit foption;

interface

uses Classes;

procedure kSetOption( OptionName: String; const OptionValue: String);
function kGetOption( OptionName: String; const Default:String=''):String;

implementation

var
  lOptions: TStringList;

procedure kSetOption( OptionName: String; const OptionValue: String);
begin
  lOptions.Values[OptionName] := OptionValue;
end;  // kSetOption

function kGetOption( OptionName: String; const Default:String=''):String;
begin
  Result := Default;
  if lOptions.IndexOfName(OptionName) > -1 then
    Result := lOptions.Values[OptionName];
end;  // kGetOption

initialization
  lOptions := TStringList.Create;

finalization
  lOptions.Free;

end.
