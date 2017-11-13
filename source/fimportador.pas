{
Projeto FolhaLivre - Folha de Pagamento Livre
fimportador.pas - Importador de Lan�amentos para Eventos Informados

Copyright (c) 2007 Allan Lima, Bel�m-Par�-Brasil.

Este programa � um software de livre distribui��o, que pode ser copiado e
distribu�do sob os termos da Licen�a P�blica Geral GNU, conforme publicada
pela Free Software Foundation, vers�o 2 da licen�a ou qualquer vers�o posterior.

Este programa � distribu�do na expectativa de ser �til aos seus usu�rios,
por�m  N�O TEM NENHUMA GARANTIA, EXPL�CITAS OU IMPL�CITAS,
COMERCIAIS OU DE ATENDIMENTO A UMA DETERMINADA FINALIDADE.

Consulte a Licen�a P�blica Geral GNU para maiores detalhes.

Hist�rico
---------

* 31/07/2007 - Primeira vers�o

}

{$IFNDEF QFLIVRE}
unit fimportador;
{$ENDIF}

{$IFNDEF NO_FLIVRE.INC}
  {$I flivre.inc}
{$ENDIF}

interface

uses
  {$IFDEF CLX}QGraphics, QControls, QForms, QDialogs, QStdCtrls,{$ENDIF}
  {$IFDEF VCL}Windows, Graphics, Controls, Forms, Dialogs, StdCtrls,{$ENDIF}
  SysUtils, Classes;

type
  TFrmImportar = class(TForm)
  private
    { Private declarations }
    pvEmpresa, pvFolha: Integer;
    dbArquivo: TEdit;
    dbOpcao: TCheckBox;
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ProcurarClick(Sender: TObject);
    procedure ImportarClick(Sender: TObject);
    procedure ExcluirClick(Sender: TObject);
  public
    { Public declarations }
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
  end;

procedure ImportarInformado( Empresa: Integer; Folha: Integer); overload;

function ImportarInformado( Empresa: Integer; Folha: Integer;
  Eventos: array of Integer; FileName: String; Combinar: Boolean):Boolean; overload;

implementation

uses fdb, ftext, fsuporte, fevento, fprogress, Math, fcolor;

procedure ImportarInformado( Empresa: Integer; Folha: Integer);
begin

  with TFrmImportar.CreateNew(NIL) do
  try
    pvEmpresa := Empresa;
    pvFolha := Folha;
    ShowModal;
  finally
    Free;
  end;

end;

function ImportarInformado( Empresa: Integer; Folha: Integer;
  Eventos: array of Integer; FileName: String; Combinar: Boolean):Boolean;
var
  i, iFuncionario, iEvento, iID: Integer;
  sInformado, sDelete, sInsert, sLine: String;
  lSQL, lLine, lEmployee: TStringList;
  cInformado: Currency;
  iCountEvento: Integer;
  fProgress: TFrmProgress;
  fs : TFormatSettings;
begin

  Result := False;

  if not FileExists(FileName) then
    raise Exception.Create('O arquivo '+FileName+' n�o existe. Verifique.');

  if not kStartTransaction() then
    raise Exception.Create('N�o foi poss�vel iniciar a importa��o.'+sLineBreak+
                           'Erro ao iniciar "transa��o" para o banco de dados');

  // Instrucao SQL que sera processada antes da insercao de um lancamento
  // para evitar a duplicacao do lancamento
  sDelete := 'DELETE FROM F_INFORMADO'+sLineBreak+
      'WHERE IDEMPRESA = :EMPRESA AND IDFOLHA = :FOLHA'+sLineBreak+
      'AND IDFUNCIONARIO = :FUNCIONARIO AND IDEVENTO = :EVENTO';

  sInsert := 'INSERT INTO F_INFORMADO'+sLineBreak+
      '(IDEMPRESA, IDFOLHA, IDFUNCIONARIO, ID, IDEVENTO, INFORMADO)'+sLineBreak+
      'VALUES (:EMPRESA, :FOLHA, :FUNCIONARIO, :ID, :EVENTO, :INFORMADO)';

  lSQL := TStringList.Create;
  lLine := TStringList.Create;
  lEmployee := TStringList.Create;

  fProgress := CriaProgress('',True);

  iFuncionario := 0;
  iCountEvento := Length(Eventos)-1;

  try
    fs:= TFormatSettings.Create();
    try

      lSQL.LoadFromFile(FileName);
      fProgress.MaxValue := lSQL.Count;

      for i := 0 to lSQL.Count - 1 do
      begin

        // Separa as partes de cada linha do arquivo
        sLine := Trim(lSQL.Strings[i]);
        kBreakApart( sLine, #32, lLine);

        if (lLine.Count < 2) or (lLine.Count > 3) then
          raise Exception.CreateFmt(
                  'Erro na linha de n�mero %d'+sLineBreak+sLineBreak+
                  'N�mero insuficiente de campos (dados)'+sLineBreak+sLineBreak+
                  'Conte�do da linha: '+QuotedStr(sLine), [i+1]);

        if (lLine.Count = 3) then
        begin
          iEvento := StrToInt(lLine.Strings[2]);  // Evento informado na linha
          if (iEvento < 1) then
            raise Exception.CreateFmt(
                    'Erro na linha de n�mero %d'+sLineBreak+sLineBreak+
                    'C�digo inv�lido para evento: %d'+sLineBreak+sLineBreak+
                    'Conte�do da linha: '+QuotedStr(sLine), [i+1,iEvento]);
        end else
          iEvento := -1;   // Considera a lista de eventos informados

        if (iFuncionario <> StrToInt(lLine.Strings[0])) then
        begin

          if Combinar and (iCountEvento <> Length(Eventos)-1) then
            raise Exception.CreateFmt(
                    'Erro na linha de n�mero %d'+sLineBreak+sLineBreak+
                    'O n�mero de lan�amentos para o funcion�rio anterior � diferente do n�mero de eventos especificados'+sLineBreak+sLineBreak+
                    'Conte�do da linha: '+QuotedStr(sLine), [i+1]);

          iFuncionario := StrToInt(lLine.Strings[0]);

          if (lEmployee.IndexOf(IntToStr(iFuncionario)) > -1) then
            raise Exception.CreateFmt(
                    'Erro na linha de n�mero %d'+sLineBreak+sLineBreak+
                    'O arquivo n�o est� ordenado.'+sLineBreak+
                    'O funcion�rio j� foi processado.'+sLineBreak+sLineBreak+
                    'Conte�do da linha: '+QuotedStr(sLine), [i+1]);

          lEmployee.Add(IntToStr(iFuncionario));
          iCountEvento := 0;  // Considera o primeiro evento da lista

        end else
          Inc(iCountEvento);  // Considera o proximo evento da lista

        if ((iCountEvento+1) > Length(Eventos)) then
          raise Exception.CreateFmt(
                  'Erro na linha de n�mero %d'+sLineBreak+sLineBreak+
                  'O n�mero de lan�amentos para o funcion�rio excedeu o n�mero de eventos especificados'+sLineBreak+sLineBreak+
                  'Conte�do da linha: '+QuotedStr(sLine), [i+1]);

        sInformado := lLine.Strings[1];

        if Pos(':', sInformado) > 0 then
          sInformado := kSubstitui(sInformado,':', fs.DecimalSeparator);

        if (fs.DecimalSeparator <> ',') and (Pos(',', sInformado) > 0) then
          sInformado := kSubstitui(sInformado, ',', fs.DecimalSeparator);

        if (fs.DecimalSeparator <> '.') and (Pos('.', sInformado) > 0) then
          sInformado := kSubstitui(sInformado, '.', fs.DecimalSeparator);

        cInformado := StrToCurr(sInformado);

        if (iEvento = -1) then
          iEvento := Eventos[iCountEvento];

        if (iEvento <> 0) then
        begin

          if not kExecSQL( sDelete,
                    [Empresa, Folha, iFuncionario, iEvento], False) then
            raise Exception.Create(kGetErrorLastSQL);

          iID := kMaxCodigo( 'F_INFORMADO', 'ID', Empresa,
                             'IDFOLHA = '+IntToStr(Folha)+
                             ' AND IDFUNCIONARIO = '+IntToStr(iFuncionario), False);

          if not kExecSQL( sInsert,
                    [Empresa, Folha, iFuncionario,iID,iEvento,cInformado], False) then
            raise Exception.Create(kGetErrorLastSQL);

        end;

        fProgress.AddProgress(1);
        fProgress.Mensagem := 'Importando linha '+
                              IntToStr(i+1)+' de '+IntToStr(fProgress.MaxValue);

      end;

      if Combinar and (iCountEvento <> Length(Eventos)-1) then
        raise Exception.Create(
                'Erro na �ltima linha do arquivo'+sLineBreak+sLineBreak+
                'O n�mero de lan�amentos para o funcion�rio � diferente do n�mero de eventos especificados'+sLineBreak+sLineBreak+
                'Conte�do da linha: '+QuotedStr(sLine));

      Result := True;

    except
      on E:Exception do
      begin
        if kInTransaction() then
          kRollbackTransaction();
        fProgress.Visible := False;
        kErro(E.Message);
      end;
    end;
  finally
    FreeAndNil( fs );
    if kInTransaction() then
      kCommitTransaction();
    lLine.Free;
    lSQL.Free;
    lEmployee.Free;
    fProgress.Free;
  end;

  if Result then
    kAviso('Parab�ns !!! A importa��o foi realizada com sucesso.');

end;  // ImportarInformado

{ TFrmImportar }

constructor TFrmImportar.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
var
  Label1: TLabel;
  Group1: TGroupBox;
  Button1: TButton;
  Control1, Control2: TControl;
  iLeft, iTop: Integer;
begin

  inherited;

  Caption := 'Importa��o de Arquivo de Lan�amento';

  WindowState := wsNormal;
  Position := poScreenCenter;
  BorderStyle := bsDialog;

  Ctl3D := False;
  Color := kGetColor();

  ClientHeight := Round(Application.MainForm.Height * 0.5);
  ClientWidth := Round(Application.MainForm.Width * 0.6);
  KeyPreview := True;

  OnKeyDown := FormKeyDown;

  // Arquivo

  Group1 := TGroupBox.Create(Self);

  Group1.Parent := Self;
  Group1.Top := 8;
  Group1.Left := 8;
  Group1.Width := ClientWidth - (Group1.Left * 2);
  Group1.Caption := 'Arquivo para Importa��o - [F12] para procurar arquivos';

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  TLabel(Label1).Caption := 'Arquivo a ser importado';
  TLabel(Label1).Font.Style := [fsBold];
  Label1.Top := 20;
  Label1.Left := 8;

  dbArquivo := TEdit.Create(Self);

  dbArquivo.Parent := Label1.Parent;
  dbArquivo.Left := Label1.Left;
  dbArquivo.Top := Label1.Top + Label1.Height + H_SEPARATOR;
  dbArquivo.Text := '';
  dbArquivo.Font.Color := clBlue;
  dbArquivo.Font.Style := [fsBold];

  Button1 := TButton.Create(Self);

  Button1.Parent := Group1;
  Button1.Caption := '&Procurar Arquivo...';
  Button1.Top := dbArquivo.Top - ((Button1.Height - dbArquivo.Height) div 2);
  Button1.Width := Round(Canvas.TextWidth(Button1.Caption)*1.5);
  Button1.Left := Group1.ClientWidth - (Button1.Width + 8);
  Button1.OnClick := ProcurarClick;
  Button1.Name := 'bprocurar';

  dbArquivo.Width := Button1.Left - (dbArquivo.Left + W_SEPARATOR);

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Left := 8;
  Label1.Top := dbArquivo.Top + dbArquivo.Height + (H_SEPARATOR*2);
  Label1.WordWrap := True;
  Label1.Caption := '* Cada linha do arquivo deve estar no formato: '+
                    '<funcion�rio><espa�o><valor> ou <funcion�rio><espa�o><valor><espa�o><evento>';
  Label1.AutoSize := False;
  Label1.Width := Group1.ClientWidth - (Label1.Left * 2);
  Label1.Font.Style := [fsBold];
  Label1.Font.Color := clRed;
  Label1.Height := Canvas.TextHeight('P') *
                   ( ( Round((Canvas.TextWidth(Label1.Caption)*1.3)) div Label1.Width) + 1) ;

  Group1.Height := Label1.Top + Label1.Height + H_SEPARATOR*2;

  iTop := Group1.Top + Group1.Height;

  // Eventos

  Group1 := TGroupBox.Create(Self);

  Group1.Parent := Self;
  Group1.Top := iTop + 10;
  Group1.Left := 8;
  Group1.Width := ClientWidth - (Group1.Left * 2);
  Group1.Caption := 'Lista de Eventos - [F12] para procurar os eventos';

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Top := 20;
  Label1.Left := 8;
  Label1.Caption := 'Primeiro Evento';
  Label1.Font.Style := [fsBold];
  Label1.Hint := 'Entre com o c�digo ou com parte do nome e tecle [Enter]';
  Label1.ShowHint := True;

  Control1 := TEdit.Create(Self);

  Control1.Parent := Label1.Parent;
  Control1.Left := Label1.Left;
  Control1.Top := Label1.Top + Label1.Height + H_SEPARATOR;
  Control1.Width := 50;
  Control1.Name := 'dbevento1';
  TEdit(Control1).Text := '';
  Control1.Hint := Label1.Hint;
  Control1.ShowHint := Label1.ShowHint;

  Control2 := TEdit.Create(Self);

  Control2.Parent := Label1.Parent;
  Control2.Left := Control1.Left + Control1.Width + W_SEPARATOR;
  Control2.Top := Control1.Top;
  Control2.Width := Group1.ClientWidth - (Control2.Left + 8);
  Control2.Name := 'dbnome1';
  TEdit(Control2).Text := '';
  TEdit(Control2).ParentColor := True;
  TEdit(Control2).TabStop := False;

  ///

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Top := Control1.Top + Control1.Height + H_SEPARATOR;
  Label1.Left := Control1.Left;
  Label1.Caption := 'Segundo Evento';
  Label1.Font.Style := [fsBold];
  Label1.Hint := Control1.Hint;
  Label1.ShowHint := Control1.ShowHint;

  Control1 := TEdit.Create(Self);

  Control1.Parent := Label1.Parent;
  Control1.Left := Label1.Left;
  Control1.Top := Label1.Top + Label1.Height + H_SEPARATOR;
  Control1.Width := 50;
  Control1.Name := 'dbevento2';
  TEdit(Control1).Text := '';
  Control1.Hint := Label1.Hint;
  Control1.ShowHint := Label1.ShowHint;

  Control2 := TEdit.Create(Self);

  Control2.Parent := Label1.Parent;
  Control2.Left := Control1.Left + Control1.Width + W_SEPARATOR;
  Control2.Top := Control1.Top;
  Control2.Width := Group1.ClientWidth - (Control2.Left + 8);
  Control2.Name := 'dbnome2';
  TEdit(Control2).Text := '';
  TEdit(Control2).ParentColor := True;
  TEdit(Control2).TabStop := False;

  ///

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Top := Control1.Top + Control1.Height + H_SEPARATOR;
  Label1.Left := Control1.Left;
  Label1.Caption := 'Terceiro Evento';
  Label1.Font.Style := [fsBold];
  Label1.Hint := Control1.Hint;
  Label1.ShowHint := Control1.ShowHint;

  Control1 := TEdit.Create(Self);

  Control1.Parent := Label1.Parent;
  Control1.Left := Label1.Left;
  Control1.Top := Label1.Top + Label1.Height + H_SEPARATOR;
  Control1.Width := 50;
  Control1.Name := 'dbevento3';
  TEdit(Control1).Text := '';
  Control1.Hint := Label1.Hint;
  Control1.ShowHint := Label1.ShowHint;

  Control2 := TEdit.Create(Self);

  Control2.Parent := Label1.Parent;
  Control2.Left := Control1.Left + Control1.Width + W_SEPARATOR;
  Control2.Top := Control1.Top;
  Control2.Width := Group1.ClientWidth - (Control2.Left + 8);
  Control2.Name := 'dbnome3';
  TEdit(Control2).Text := '';
  TEdit(Control2).ParentColor := True;
  TEdit(Control2).TabStop := False;

  ///

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Top := Control1.Top + Control1.Height + H_SEPARATOR;
  Label1.Left := Control1.Left;
  Label1.Caption := 'Quarto Evento';
  Label1.Font.Style := [fsBold];
  Label1.Hint := Control1.Hint;
  Label1.ShowHint := Control1.ShowHint;

  Control1 := TEdit.Create(Self);

  Control1.Parent := Label1.Parent;
  Control1.Left := Label1.Left;
  Control1.Top := Label1.Top + Label1.Height + H_SEPARATOR;
  Control1.Width := 50;
  Control1.Name := 'dbevento4';
  TEdit(Control1).Text := '';
  Control1.Hint := Label1.Hint;
  Control1.ShowHint := Label1.ShowHint;

  Control2 := TEdit.Create(Self);

  Control2.Parent := Label1.Parent;
  Control2.Left := Control1.Left + Control1.Width + W_SEPARATOR;
  Control2.Top := Control1.Top;
  Control2.Width := Group1.ClientWidth - (Control2.Left + 8);
  Control2.Name := 'dbnome4';
  TEdit(Control2).Text := '';
  TEdit(Control2).ParentColor := True;
  TEdit(Control2).TabStop := False;

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Left := 8;
  Label1.Top := Control2.Top + Control2.Height + 10;
  Label1.WordWrap := True;
  Label1.Caption := '* Para usar mais de um evento o arquivo dever� est� ordenado por funcion�rio e evento';
  Label1.AutoSize := False;
  Label1.Width := Group1.ClientWidth - (Label1.Left * 2);
  Label1.Font.Style := [fsBold];
  Label1.Font.Color := clRed;
  Label1.Height := Canvas.TextHeight('P') *
                   ( ( Round((Canvas.TextWidth(Label1.Caption)*1.3)) div Label1.Width) + 1) ;

  Group1.Height := Label1.Top + Label1.Height + H_SEPARATOR * 2;

  iLeft := Group1.Left;
  iTop := Group1.Top + Group1.Height;

  Group1 := TGroupBox.Create(Self);

  Group1.Parent := Self;
  Group1.Top := iTop + H_SEPARATOR;
  Group1.Left := iLeft;
  Group1.Width := ClientWidth - (Group1.Left * 2);
  Group1.Caption := 'Configura��es';

  dbOpcao := TCheckBox.Create(Self);

  dbOpcao.Parent := Group1;
  dbOpcao.Left := 8;
  dbOpcao.Top := 20;
  dbOpcao.Caption :=  'O no. de lan�amentos deve ser igual ao no. de eventos especificados acima';
  dbOpcao.Checked := True;
  dbOpcao.Width := Round(Canvas.TextWidth(dbOpcao.Caption)*1.1);

  Label1 := TLabel.Create(Self);

  Label1.Parent := Group1;
  Label1.Left := 8;
  Label1.Top := dbOpcao.Top + dbOpcao.Height + H_SEPARATOR * 2 ;
  Label1.WordWrap := True;
  Label1.Caption := '* Para desconsiderar os lan�amentos de determinada posi��o informe "0" para o evento correspondente';
  Label1.AutoSize := False;
  Label1.Width := Group1.ClientWidth - (Label1.Left * 2);
  Label1.Font.Style := [fsBold];
  Label1.Font.Color := clRed;
  Label1.Height := Canvas.TextHeight('P') *
                   ( ( Round((Canvas.TextWidth(Label1.Caption)*1.3)) div Label1.Width) + 1) ;

  Group1.Height := Label1.Top + Label1.Height + H_SEPARATOR * 2;

  // Botoes "Excluir", "Importar" e "Fechar"

  Button1 := TButton.Create(Self);

  Button1.Parent := Self;
  Button1.Left := Group1.Left;
  Button1.Top := Group1.Top + Group1.Height + H_SEPARATOR * 2;
  Button1.Caption := '&Excluir Lan�amentos';
  Button1.Width := Round(Canvas.TextWidth(Button1.Caption)*1.5);
  Button1.OnClick := ExcluirClick;

  iLeft := Button1.Left + Button1.Width;
  iTop  := Button1.Top;

  Button1 := TButton.Create(Self);

  Button1.Parent := Self;
  Button1.Left := iLeft + 10;
  Button1.Top := iTop;
  Button1.Caption := '&Importar Arquivo';
  Button1.Width :=  Round(Canvas.TextWidth(Button1.Caption)*1.5);
  Button1.Font.Style := [fsBold];
  Button1.OnClick := ImportarClick;

  iLeft := Button1.Left + Button1.Width;
  iTop  := Button1.Top;

  Button1 := TButton.Create(Self);

  Button1.Parent := Self;
  Button1.Left := iLeft + 10;
  Button1.Top := iTop;
  Button1.Caption := '&Fechar';
  Button1.Width :=  Round(Canvas.TextWidth(Button1.Caption)*1.5);
  Button1.ModalResult := mrCancel;

  ClientHeight := Button1.Top + Button1.Height + 10;

end;

procedure TFrmImportar.ExcluirClick(Sender: TObject);
var
  lEventos: TStringList;
  bSucess: Boolean;
  sEvento: String;
  i: Integer;
begin

  lEventos := TStringList.Create;
  bSucess := False;

  try

    i := 1;

    while Assigned(Self.FindComponent('dbevento'+IntToStr(i))) do
    begin
      sEvento := TEdit(Self.FindComponent('dbevento'+IntToStr(i))).Text;
      if (sEvento <> EmptyStr) then
        lEventos.Add(sEvento);
      Inc(i);
    end;

    if (lEventos.Count = 0) then
    begin
      kAviso('N�o � poss�vel realizar a exclus�o dos lan�amentos !!!'+sLineBreak+sLineBreak+
             'Nenhum evento foi informado. Verifique.');
      Exit;
    end;

    if not kConfirme('O sistema realizar� a exclus�o dos lan�amentos referente aos eventos especificados.'+sLineBreak+
                     'Essa opera��o n�o poder� ser desfeita, salvo ser ocorrer algum erro.'+sLineBreak+sLineBreak+
                     'Deseja prosseguir com a exclus�o dos lan�amentos?') then
      Exit;

    try try

      if not kStartTransaction() then
        raise Exception.Create('N�o foi poss�vel excluir os lan�amentos.'+sLineBreak+
                               'Ocorreu um erro ao iniciar "transa��o" no banco de dados');

      for i := 0 to lEventos.Count - 1 do
        if not kExecSQL( 'DELETE FROM F_INFORMADO'+sLineBreak+
                         'WHERE IDEMPRESA = :EMPRESA AND IDFOLHA = :FOLHA AND IDEVENTO = :EVENTO',
                         [pvEmpresa, pvFolha, StrToInt(lEventos[i])], False) then
           raise Exception.Create(kGetErrorLastSQL);

    except
      if kInTransaction() then
        kRollbackTransaction();
    end;
    finally
      if kInTransaction() then
        bSucess := kCommitTransaction();
    end;

  finally
    lEventos.Free;
  end;

  if bSucess then
    kAviso( 'Todos os lan�amentos do(s) evento(s) informado(s) foram exclu�dos !!!', mtInformation);

end;  //  ExcluirClick()

procedure TFrmImportar.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  iEvento, iAtivo: Integer;
  sNome, sTipo, sText, sActiveName: String;
begin

  sActiveName := ActiveControl.Name;

  if ( (ActiveControl = dbArquivo) or (Pos('bprocurar',sActiveName) > 0) ) and
     (Key = VK_F12) then

    ProcurarClick(NIL)

  else if (Pos('dbevento',sActiveName) > 0) and (Key = VK_RETURN) then
  begin

    sText := TEdit(ActiveControl).Text;

    if (sText = EmptyStr) then
      TEdit(Self.FindComponent(kSubstitui(sActiveName,'evento', 'nome'))).Text := ''

    else if (sText = '0') then
      TEdit(Self.FindComponent(kSubstitui(sActiveName,'evento', 'nome'))).Text := 'DESCONSIDERAR LAN�AMENTOS NO ARQUIVO'

    else if not kEventoFind( sText, iEvento, sNome, sTipo, iAtivo) then
    begin
      kErro('Evento n�o encontrado. Tente novamente !!!');
      TEdit(ActiveControl).Text := '';
      TEdit(Self.FindComponent(kSubstitui(sActiveName,'evento', 'nome'))).Text := '';
      Key := 0;

    end else if (iAtivo = 0) and
            not kConfirme('O evento escolhido est� desativado.'+sLineBreak+sLineBreak+
                          'Isso significa que o mesmo n�o ser� calculado.'+sLineBreak+sLineBreak+
                          'Deseja continuar assim mesmo?') then
      Key := 0

    else
    begin
      TEdit(ActiveControl).Text := IntToStr(iEvento);
      TEdit(Self.FindComponent(kSubstitui(sActiveName,'evento', 'nome'))).Text := sNome;
    end;

  end else if (Pos('dbevento',sActiveName) > 0) and (Key = VK_F12) then
  begin

    if not kEventoFind( '*', iEvento, sNome, sTipo, iAtivo) then
    begin
      kErro('Evento n�o encontrado. Tente novamente !!!');
      Key := 0;
    end else if (iAtivo = 0) and
            not kConfirme('O evento escolhido est� desativado.'+sLineBreak+sLineBreak+
                          'Isso significa que o mesmo n�o ser� calculado.'+sLineBreak+sLineBreak+
                          'Deseja continuar assim mesmo?') then
      Key := 0
    else
    begin
      TEdit(ActiveControl).Text := IntToStr(iEvento);
      TEdit(Self.FindComponent(kSubstitui(sActiveName,'evento', 'nome'))).Text := sNome;
      Key := VK_RETURN;
    end;

  end;

  kKeyDown(Self, Key, Shift);

end;  //  FormKeyDown()

procedure TFrmImportar.ImportarClick(Sender: TObject);
var
  aEventos: array of Integer;
  lEventos: TStringList;
  sEvento: String;
  i: Integer;
begin

  if (dbArquivo.Text = EmptyStr) then
    raise Exception.Create('Falta informar o arquivo. Verifique.');

  lEventos := TStringList.Create;

  try

    i := 1;

    while Assigned(Self.FindComponent('dbevento'+IntToStr(i))) do
    begin
      sEvento := TEdit(Self.FindComponent('dbevento'+IntToStr(i))).Text;
      if (sEvento <> EmptyStr) then
        lEventos.Add(sEvento);
      Inc(i);
    end;

    if (lEventos.Count = 0) and
       not kConfirme('Nenhum evento foi informado para a importa��o !!!'+sLineBreak+sLineBreak+
                     'O c�digo do evento dever� constar no arquivo na 3a. posi��o de cada linha.'+sLineBreak+
                     'Deseja prosseguir com a importa��o ?') then
        Exit;

    if (lEventos.Count > 0) then
    begin
      SetLength( aEventos, lEventos.Count);
      for i := 0 to lEventos.Count - 1 do
        aEventos[i] := StrToInt(lEventos[i]);
    end;

    ImportarInformado( pvEmpresa, pvFolha, aEventos, dbArquivo.Text, dbOpcao.Checked);

  finally
    lEventos.Free;
  end;

end;

procedure TFrmImportar.ProcurarClick(Sender: TObject);
begin

  with TOpenDialog.Create(NIL) do
  try

    InitialDir := ExtractFilePath(ParamStr(0));

    Filter := 'Arquivos de Textos (*.txt)|*.txt|'+
                    'Todos os Arquivos (*.*)|*.*';
    DefaultExt := '*.txt';

    if not Execute then
      Exit;

    dbArquivo.Text := FileName;

  finally
    Free;
  end;

end;


end.
