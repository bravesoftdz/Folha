{
Projeto FolhaLivre - Folha de Pagamento Livre
Copyright (c) 2007 Allan Lima

O FolhaLivre � um software de livre distribui��o, que pode ser copiado e
distribu�do sob os termos da Licen�a P�blica Geral GNU, conforme publicada
pela Free Software Foundation, vers�o 2 da licen�a ou qualquer vers�o posterior.

Este programa � distribu�do na expectativa de ser �til aos seus usu�rios,
por�m  N�O TEM NENHUMA GARANTIA, EXPL�CITAS OU IMPL�CITAS,
COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.

Consulte a Licen�a P�blica Geral GNU para maiores detalhes.

Hist�rico das altera��es

* 19/11/2007 - Primeira versao

}

unit flivre_util;

interface

  TInfo = class
  private
    TEmpresa: Integer;
    TFolha: Integer;
    TGrupoEmpresa: Integer;
    TGrupoPagamento: Integer;
  protected
  public
    property Empresa: Integer read TEmpresa write TEmpresa;
    property Folha: Integer read TFolha write TFolha;
    property GrupoEmpresa: Integer read TGrupoEmpresa write TGrupoEmpresa;
    property GrupoPagamento: Integer read TGrupoPagamento write TGrupoPagamento;
  end;

var
  vInfo: TInfoFolhaLivre;

implementation

initialization
  vInfo :=

finalization


end.
